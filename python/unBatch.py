import os
import re
import sys
import argparse
import numpy as np
import scipy.sparse as sp
# Add paths
pv_path = os.path.abspath(
    os.environ['HOME']+'/workspace/OpenPV/python/')
sys.path.insert(0, pv_path) 
from pvtools import *

# Debug
#from IPython import embed;

parser = argparse.ArgumentParser(description =
    "Concatenates the frames in batch pvp files into a sequential file.",
    usage="unBatch.py -i <input_path> -o <output_path> -f <file_name> ")

parser.add_argument("-i", "--input-path", type=str, required=True,
    help="Path to parent directory to start traversing for files.")
parser.add_argument("-o", "--output-path", type=str, default=None,
    required=True, help="Where to save output pvp file.")
parser.add_argument("-f", "--file-name", type=str, default='S1.pvp',
    required=False, help="File name to search for. Default: S1.pvp")
parser.add_argument("-n", "--num-frames", type=int, required=False, 
    help="Number of frames to include in output file. Default uses all frames.")
parser.add_argument("-m", "--memory-optimized", action="store_true", 
    required=False, help="If set, program will use less memory and take longer.")


def findPvpFiles(input_path, file_name):
    base, extension = os.path.splitext(file_name.lower())
    print 'Recursively searching for %s in %s...' % (file_name, input_path)
    path_list = []
    for dir_path, file_path, file_names in os.walk(input_path):
        if dir_path.endswith('.AppleDouble'):
            continue
        for f in file_names:
            if re.search('\A'+base+'_\d+'+extension, f.lower()) and not f.startswith('.'):
                path_list.append(os.path.join(dir_path, f))
    path_list.sort()
    return path_list

def openPvpFiles(path_list):
    print 'Opening pvp files for writing...'
    file_objects = []
    for pvp_idx, pvp_file in enumerate(path_list):
        file_objects.append(pvpOpen(pvp_file, 'r'))
    pv_header = file_objects[0].read(0,1,1,0)['header']
    return file_objects, pv_header

def loadPvpFiles(path_list):
    print 'Reading pvp files...'
    pv_values = []
    for pvp_idx, pvp_file in enumerate(path_list):
        file_object = pvpOpen(pvp_file, 'r')
        if pvp_idx == 0:
            pv_header = file_object.read(0,1,1,0)['header']
        pv_values.append(file_object.read()['values'])
        file_object.close()
    return pv_values, pv_header

def main(args=None):
    args = parser.parse_args()
    input_path = os.path.abspath(args.input_path)
    assert os.path.isdir(input_path), "Invalid input path."
    output_path = os.path.abspath(args.output_path)
    memory_optimized = args.memory_optimized

    path_list = findPvpFiles(input_path, args.file_name)

    if memory_optimized == True:
        file_objects, pv_header = openPvpFiles(path_list)
    else:
        pv_values, pv_header = loadPvpFiles(path_list)

    num_pvp_files = len(path_list)
    out_dict = {}
    pv_time = []

    n_local_batch = pv_header['nbatch']
    n_batches = pv_header['nbands']
    if args.num_frames is not None:
        num_frames = args.num_frames
    else:
        num_frames = num_pvp_files * pv_header['nbands']

    # NOTE: The following method is for batchMethod 'byImage'
    num_neurons = pv_header['ny']*pv_header['nx']*pv_header['nf']
    pvp_shape = (pv_header['ny'], pv_header['nx'], pv_header['nf'])
    #out_values = sp.csr_matrix((num_frames, num_neurons))
    out_values = []
    out_time = np.zeros((num_frames))
    current_frame = 0
    for batch in range(0, n_batches, 2):
        for pvp_frame in range(num_pvp_files):
            for local_batch in range(n_local_batch):
                if current_frame >= num_frames:break
                idx  = batch + local_batch
                print "Frame: %d Batch: %d PVPFrame: %d" % (current_frame, idx, pvp_frame)
                if memory_optimized == True:
                    current_data = file_objects[pvp_frame].read(idx,idx+1,1,0)
                    out_values.append(current_data['values'])
                    out_time[current_frame] = current_data['time']
                else:
                    out_values.append(pv_values[pvp_frame][idx, :])
                    out_time[current_frame] = current_frame
                current_frame += 1

    write_object = pvpOpen(output_path, 'w')
    print "Concatenating"
    out_dict['values'] = sp.vstack(out_values, format='csr')
    out_dict['time'] = out_time

    print 'Writing pvp file ...'
    write_object.write(out_dict, pvp_shape)
    write_object.close()
    #embed()

if __name__ == "__main__":
    main()
