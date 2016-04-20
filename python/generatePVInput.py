import os
#import sys
import argparse
import xml.etree.cElementTree as cet
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
    usage="generatePVInput.py <input_path> <output_path> [-e 'png']")

parser.add_argument("input_path", type=str, help="Path to input directory.")
parser.add_argument("output_path", type=str, help="Path to output directory.")
parser.add_argument("-e", "--file-extension", type=str, default='jpg',
    required=False, help="Filetype to look for.")
parser.add_argument("-a", "--annotation-path", type=str, required=False,
    help="Root path of annotations.")

def get_file_list(path, extension):
    print "Searching %s for %s files..." % (path, extension)
    path_list = []

    for dir_path, file_path, file_names in os.walk(path):
        if dir_path.endswith('.AppleDouble'):
            continue
        for f in file_names:
            if f.lower().endswith((extension)) and not f.startswith('.'):
                path_list.append(os.path.join(dir_path, f))
    print "Found %d files." % len(path_list)
    print "Sorting path list..."
    path_list.sort()
    return path_list

def ILSVRC_xml_parse(xml_path):
    annotated_objects = []
    tree = cet.parse(xml_path)
    root = tree.getroot()
    for det_object in root.iter('object'):
        bounding_box = []
        bounding_box.append(det_object.find('name').text)
        bounding_box.append(det_object.find('bndbox/xmin').text)
        bounding_box.append(det_object.find('bndbox/xmax').text)
        bounding_box.append(det_object.find('bndbox/ymin').text)
        bounding_box.append(det_object.find('bndbox/ymax').text)
        annotated_objects.append(bounding_box)

    return annotated_objects

def display_annotation(image_path, annotated_objects):
    print "Drawing annotations..."

def write_list_to_file(image_list, output_path):
    fpath = output_path + '/path_list.txt'
    out_file = open(fpath, 'w')
    print "Writing path list to %s..." % (fpath)
    for line in image_list:
        print>>out_file, line
    out_file.close()

def main(args=None):
    args = parser.parse_args()
    input_path = os.path.abspath(args.input_path)
    output_path = os.path.abspath(args.output_path)
    file_extension = '.'+args.file_extension.replace('.', '').lower()
    assert os.path.isdir(input_path), "Invalid input path."
    assert os.path.isdir(output_path), "Invalid output path."
    if args.annotation_path is not None:
        annotation_path = os.path.abspath(args.annotation_path)
        assert os.path.isdir(annotation_path), "Invalid annotation path."

    image_list = get_file_list(input_path, file_extension)
    xml_list = get_file_list(annotation_path, '.xml')
    annotated_objects = ILSVRC_xml_parse(xml_list[10556])



    #write_list_to_file(image_list, output_path)

    embed()


if __name__ == "__main__":
    main()
