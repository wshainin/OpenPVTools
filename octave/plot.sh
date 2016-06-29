#!/bin/bash

for i in {0..7}
do
    BS=0$i
    CP=0000090000
    FM=0
    octave --eval "plotRecon('/home/wshainin/workspace/imageNet/VID128x72/ImageNetVID_128X72_S1X28_16X16_2X3frames/train_batch1/Checkpoints/batchsweep_$BS/Checkpoint$CP/Frame${FM}_A.pvp', '/home/wshainin/workspace/imageNet/VID128x72/ImageNetVID_128X72_S1X28_16X16_2X3frames/train_batch1/Checkpoints/batchsweep_$BS/Checkpoint$CP/Frame${FM}ReconS1_A.pvp')"
    mv Recon/00001.png Recon/B${BS}_${CP}_${FM}.png
done
