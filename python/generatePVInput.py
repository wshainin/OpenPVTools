import os
#import sys
import argparse
#import numpy as np
#import math
#import matplotlib.pyplot as plt
#from skimage import exposure
#from PIL import Image
#from scipy.misc import toimage
# Add paths
#pv_path = os.path.abspath(
#    os.environ['HOME']+'/workspace/OpenPV/pv-core/python/')
#sys.path.insert(0, pv_path) 
#from pvtools import *

# Debug
from IPython import embed;

parser = argparse.ArgumentParser(description =
    "Traverses a directory tree and creates a txt file of image paths.",
    usage="generatePVInput.py -i <input_path> [-o output_path]")

parser.add_argument("input_path", type=str, help="Path to input directory.")
parser.add_argument("output_path", type=str, help="Output text file.")
parser.add_argument("-e", "--file-extension", type=str, default='.jpg',
    required=False, help="Filetype to look for.")

def get_image_list(path, file_extension):
    print "Searching %s for images..." % (path)
    image_list = []

    for dir_path, dir_names, file_names in os.walk(path):
        for f in file_names:
            if f.lower().endswith((file_extension)):
                image_list.append(os.path.join(dir_path, f))

    return image_list

def main(args=None):
    args = parser.parse_args()
    input_path = os.path.abspath(args.input_path)
    output_path = os.path.abspath(args.output_path)
    assert os.path.isdir(input_path), "Invalid input path."

    image_list = get_image_list(input_path, args.file_extension)

    embed()










if __name__ == "__main__":
    main()
