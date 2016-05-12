import os
import sys
import argparse
import numpy as np
import math
import matplotlib.pyplot as plt
from skimage import exposure
from PIL import Image
from scipy.misc import toimage
# Add paths
pv_path = os.path.abspath(
    os.environ['HOME']+'/workspace/OpenPV/python/')
sys.path.insert(0, pv_path) 
from pvtools import *

# Debug
#from IPython import embed;

parser = argparse.ArgumentParser(description =
    "Plots OpenPV basis vectors from checkpoints or single pvp file.",
    usage="plotWeights.py -i <input_path> [-o <output_path> -w -ns -np -he]")

parser.add_argument("-i", "--input-path", type=str, required=True, 
    help="Input. If passed a pvp file, weights at each frame will be used." +
    "If passed a directory, each checkpoint in the directory will be used.")
parser.add_argument("-o", "--output-path", type=str, default=None, 
    required=False, help="Output folder. Defaults to input directory.")
parser.add_argument("-w", "--weight-name", type=str, 
    default='S1ToImageReconS1Error_W.pvp', required=False, 
    help="Weight name. Name of weight file to look for if input is directory.")
parser.add_argument("-ns", "--no-save", action="store_true", 
    required=False, help="No save. If set, weights will not be saved to disk.")
parser.add_argument("-np", "--no-plot", action="store_true", 
    required=False, help="No plot. If set, weights will not be plotted.")
parser.add_argument("-he", "--hist-eq", action="store_true", 
    required=False, help="Histogram Equalization." +
    "If set, final image of weights will be equalized.")

def make_plot(weights_matrix, frame, hist_eq=False):
    print "Creating plot"
    num_weights = weights_matrix.shape[2]
    patch_y = weights_matrix.shape[3]
    patch_x = weights_matrix.shape[4]
    patch_f = weights_matrix.shape[5]

    subplot_x = int(math.ceil(math.sqrt(num_weights)))
    subplot_y = int(math.ceil(num_weights/float(subplot_x)))
    weights_list = list()

    for weight in range(num_weights):
        weight_patch = weights_matrix[0,0,weight]

        scale_factor = (weight_patch.max() - weight_patch.min())
        weight_patch = (weight_patch - weight_patch.min()) / scale_factor
        weights_matrix[0,0,weight] = weight_patch

    for weight_row in range(subplot_y):
        weight_start = weight_row * (subplot_x)
        weight_end = min(weight_start + subplot_x, num_weights)

        single_row = np.hstack(
                weights_matrix[frame,0,range(weight_start, weight_end),:,:,:])
        weights_list.append(single_row)

    weights_list[weight_row] = np.hstack(
        [weights_list[weight_row], 
        np.zeros([patch_y, patch_x * subplot_x, patch_f])
        ])[:, 0:(patch_x * subplot_x), :]

    weights_plot = np.vstack(weights_list)
    if hist_eq:
        weights_plot = exposure.equalize_hist(weights_plot)
    weights_plot = Image.fromarray((weights_plot * 255).astype(np.uint8))

    return weights_plot

def plot_weights(weights_plot):
    print "Plotting Weights"
    plt.figure()
    plt.imshow(weights_plot)
    plt.show()

def save_weights(weights_plot, output_path, name):
    print "Saving %s" % (name)
    if not os.path.exists(output_path):
        os.makedirs(output_path)
    weights_plot.save(output_path+'/'+name+'.png')

def main(args=None):
    args = parser.parse_args()
    assert not (args.no_plot and args.no_save), "Saving and plotting are off."
    input_path = os.path.abspath(args.input_path)
    if args.output_path is None:
        output_path = input_path
    else:
        output_path = os.path.abspath(args.output_path)

    # Input is a file.
    if os.path.isfile(input_path): 
        if os.path.isdir(output_path):
            output_path = output_path+'/weights'
        else:
            output_path = os.path.dirname(input_path)+'/weights'
        print "Loading weights from %s" % (input_path)
        pvData = readpvpfile(input_path)
        weights_matrix = pvData["values"]
        num_frames = weights_matrix.shape[0]
        for frame in range(num_frames):
            weights_plot = make_plot(weights_matrix, frame, args.hist_eq)
            if not args.no_save:
                save_weights(weights_plot, output_path, format(frame, '06d'))
        if not args.no_plot:
            plot_weights(weights_plot)

    # Input is a directory. Parse checkpoints.
    elif os.path.isdir(input_path): 
        if os.path.isdir(output_path):
            output_path = output_path+'/weights'
        else:
            output_path = input_path+'/weights'
        print "Loading weights from checkpoints"

        path_list = []
        for dir_path, file_path, file_names in os.walk(input_path):
            if dir_path.endswith('.AppleDouble'):
                continue
            for f in file_names:
                if (f.lower() == args.weight_name.lower()) and not f.startswith('.'):
                    path_list.append(os.path.join(dir_path, f))
        path_list.sort()
        for weight_file in path_list:
            pvData = readpvpfile(weight_file)
            weights_matrix = pvData["values"]
            weights_plot = make_plot(weights_matrix, 0, args.hist_eq)
            if not args.no_save:
                weight_name = os.path.splitext(args.weight_name)[0]
                checkpoint_name = os.path.split(
                        os.path.split(weight_file)[0])[1]
                save_weights(weights_plot, output_path, 
                        checkpoint_name+'_'+weight_name)
        if not args.no_plot:
            plot_weights(weights_plot)
    else:
        assert False, "Invalid input path."

if __name__ == "__main__":
    main()
