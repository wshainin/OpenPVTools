import argparse, os
import xml.etree.cElementTree as cet
from subprocess import call
from scipy.misc import imread, imsave, imresize
from matplotlib.patches import Rectangle
import matplotlib.pyplot as plt
#import numpy as np
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
    "Traverses a directory tree and creates a txt file of image paths.", usage=
    "generatePVInput.py <input_path> <output_path> [-e 'png' -a <xml_path>]")

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

def call_batch_convert(image_list, dim_list, num_procs):
    print "Calling ImageMagick's convert with image list..."
    new_list = []
    resize_str = str(dim_list[0])+'x'+str(dim_list[1])
    temp_path = os.getcwd() + '/.tmp.txt'
    temp_file = open(temp_path,'w')

    for path in image_list:
        file_path, file_extension = os.path.splitext(path)
        print>>temp_file, file_path 
        new_list.append(file_path+'_'+resize_str+file_extension)
    temp_file.close()
    
    convert_call = ('<'+temp_path+' xargs -P'+str(num_procs)+' -I % convert %'+
        file_extension+' -resize '+resize_str+'^ -gravity center -crop '+
        resize_str+'+0+0 +repage %_'+resize_str+file_extension)
    
    call(convert_call, shell=True)
    os.remove(temp_path)

    return new_list


def ILSVRC_xml_parse(xml_path):
    annotated_objects = []
    tree = cet.parse(xml_path)
    root = tree.getroot()
    for det_object in root.iter('object'):
        bounding_box = []
        bounding_box.append(det_object.find('name').text)
        bounding_box.append(int(det_object.find('bndbox/xmin').text))
        bounding_box.append(int(det_object.find('bndbox/xmax').text))
        bounding_box.append(int(det_object.find('bndbox/ymin').text))
        bounding_box.append(int(det_object.find('bndbox/ymax').text))
        annotated_objects.append(bounding_box)

    return annotated_objects

def display_annotation(image_path, annotated_objects):
    print "Drawing annotations..."
    img = imread(image_path)
    plt.imshow(img)
    for det_object in annotated_objects:
        w = det_object[2] - det_object[1]
        h = det_object[4] - det_object[3]
        box = Rectangle((det_object[1], det_object[3]), w, h, 
                        fill=False, linewidth=2.0, ec='red')
        plt.gca().add_patch(box)
    plt.show()

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

    new_list = call_batch_convert(image_list, [128, 72], 4)

    #xml_list = get_file_list(annotation_path, '.xml')
    #annotated_objects = ILSVRC_xml_parse(xml_list[10556])
    #test_image = "/Users/wshainin/lennaHome/VID/ILSVRC2015/Data/VID/train/ILSVRC2015_VID_train_0000/ILSVRC2015_train_00010001/000000.JPEG"
    #test_xml = "/Users/wshainin/lennaHome/VID/ILSVRC2015/Annotations/VID/train/ILSVRC2015_VID_train_0000/ILSVRC2015_train_00010001/000000.xml"
    #test_image =      "/Users/wshainin/lennaHome/VID/ILSVRC2015/Data/VID/train/ILSVRC2015_VID_train_0000/ILSVRC2015_train_00097000/000000.JPEG"
    #test_xml = "/Users/wshainin/lennaHome/VID/ILSVRC2015/Annotations/VID/train/ILSVRC2015_VID_train_0000/ILSVRC2015_train_00097000/000000.xml"
    
    #annotated_objects = ILSVRC_xml_parse(test_xml)
    #display_annotation(test_image, annotated_objects)



    write_list_to_file(new_list, output_path)

    embed()


if __name__ == "__main__":
    main()
