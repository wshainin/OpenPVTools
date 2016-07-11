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
    help="")
parser.add_argument("-o", "--output-path", type=str, default=None,
    required=True, help="")
parser.add_argument("-f", "--file-name", type=str, default='S1.pvp',
    required=False, help="")

def main(args=None):
    args = parser.parse_args()
    input_path = os.path.abspath(args.input_path)
    output_path = os.path.abspath(args.output_path)
    file_name, file_extension = os.path.splitext(args.file_name.lower())

    assert os.path.isdir(input_path), "Invalid input path."
    path_list = []
    print 'Recursively searching for %s in %s...' % (args.file_name, input_path)
    for dir_path, file_path, file_names in os.walk(input_path):
        if dir_path.endswith('.AppleDouble'):
            continue
        for f in file_names:
            #if f.lower().startswith(file_name+'_') and f.lower().endswith(file_extension):
            if re.search(file_name+'_\d+'+file_extension, f.lower()) and not f.startswith('.'):
                path_list.append(os.path.join(dir_path, f))
    path_list.sort()
    num_pvp_files = len(path_list)
    pv_values = []
    out_dict = {}
    pv_time = []
    pv_header = []
    n_batch = 32

    print 'Reading pvp files...'
    p = 1
    for pvp_file in path_list:
        print 'PVP file: %s/%d' % (p, num_pvp_files)
        data = readpvpfile(pvp_file)
        pv_values.append(data['values'].toarray())
        pv_time.append(data['time'])
        ## TODO: keep track of nbands in each header for num_frames (It might vary)
        pv_header.append(data['header'])
        p+=1
    del data

    num_neurons = pv_header[0]['ny']*pv_header[0]['nx']*pv_header[0]['nf']
    num_frames = pv_header[0]['nbands']
    #out_values = np.zeros((num_frames * n_batch, num_neurons))
    #out_time = np.zeros((num_frames * n_batch))

    out_values = np.zeros((num_frames * n_batch + 16, num_neurons))
    out_time = np.zeros((num_frames * n_batch + 16))
    #remain_path = '/nh/compneuro/scratch/wshainin/sandbox/CIFAR_ISTA_COMPARE_ENCODE_TEST_REMAIN_1/S1.pvp'
    #remain_frames = readpvpfile(remain_path)['values'].toarray()
    remain_path = '/nh/compneuro/scratch/wshainin/sandbox/CIFAR_ISTA_COMPARE_ENCODE_TRAIN_REMAIN_1/S1.pvp'
    remain_frames = readpvpfile(remain_path)['values'].toarray()

    out_idx = 0
    print 'Combining matrices...'
    p = 0
    for frame in range(num_frames):
        print 'Frame: %d/%d...' % (frame+1,num_frames)
        for values in pv_values:
            out_values[out_idx, :] = values[frame,:]
            out_idx+=1

    del pv_values
    del values
    for r in range(16):
        out_values[num_frames * n_batch + r,:] = remain_frames[r, :]
    del remain_frames

    print 'Generating sparse matrix...'
    out_sparse = sp.csr_matrix(out_values)
    del out_values

    out_dict['values'] = out_sparse
    out_dict['time'] = out_time
    pvp_shape = (pv_header[0]['ny'], pv_header[0]['nx'], pv_header[0]['nf'])
    print 'Writing pvp file ...'

    writepvpfile(output_path, out_dict, pvp_shape)

    #embed()

if __name__ == "__main__":
    main()
