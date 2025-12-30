"""
Script for running inference of model in C using ctypes
"""
import argparse

import sys
sys.path.append("..")

import numpy as np
import torch
import torchvision.datasets as datasets
import torchvision.transforms as transforms
from src.run_nn import load_c_lib, run_mlp
from torch.utils.data import DataLoader

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Script for testing post-training quantization of a pre-trained model in C",
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--batch_size', help='batch size', type=int, default=1)
    parser.add_argument('--data_dir', help='directory of folder containing the MNIST dataset', default='../data')

    args = parser.parse_args()

    mnist_testset = datasets.MNIST(root=args.data_dir, train=False, download=True, transform=transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
        ]))

    print(f'test data to int xs[10000][784]')
    
    test_loader = DataLoader(mnist_testset, batch_size=args.batch_size, num_workers=1, shuffle=False)
    
    test_data_h = "#ifndef __C_ARRAY_H__\n"
    test_data_h += "#define __C_ARRAY_H__\n\n"
    test_data_h += "extern int xs[10000][784];\n"
    test_data_h += "extern unsigned int ys[10000];\n\n"
    test_data_h += "#endif//__C_ARRAY_H__\n"
    
    test_data_c_xs = "int xs[10000][784] = {\n"
    test_data_c_ys = "unsigned int ys[10000] = {\n"

    for samples, labels in test_loader:
        samples = (samples * (2 ** 16)).round() # convert to fixed-point 16
        
        x = str(samples.flatten().numpy().astype(np.intc).tolist()).replace('[','{').replace(']','}')+',\n'
        y = str(labels.numpy().tolist()[0])+', '
        
        test_data_c_xs += x
        test_data_c_ys += y
    
    test_data_c_xs += "};\n\n"
    test_data_c_ys += "\n};\n"
    
    with open("../src/test_data.c","w") as f:
        f.write(test_data_c_xs)
        f.write(test_data_c_ys)
        
    with open("../src/test_data.h","w") as f:
        f.write(test_data_h)