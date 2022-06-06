import numpy as np
import scipy
from scipy import io
import torch

from spectral_np_utils import *
import random

class DataPt:
    '''
    This class holds data for a single geometry
    x - The x and y coordinates at each node
    y - The scalar field values at each node
    sdf - An NxN array of SDF values sampled across the geometry
    '''
    def __init__(self, x = None, y = None, sdf = None):
        self.x = x
        self.y = y
        self.sdf = sdf

        
def get_graph(mat,index):
    '''
    get_graph: Reads a single data point from already-loaded matlab data
    
    mat - The dictionary of values read from a .mat file
    index - The index of the data point
    
    Returns - The DataPt representation of 'mat'
    
    '''
    
    nodes = mat['nodes'][index,0].T
    elems = mat['elem'][index,0].T-1
    stress = mat['stress'][index,0]
    dt = mat['dt'][index,0]
    sdf = mat['sdf'][index][0].T
    data = DataPt(x=np.concatenate((nodes,dt),axis=1), y=stress, sdf=sdf)
    return data


def load_matlab_dataset(filename, scale = 10000):
    '''
    load_matlab_dataset: Loads a scalar field dataset from a .mat file
    
    filename - The .mat dataset consisting of meshes, the scalar field and SDF at each node, and an SDF array
    scale - The number to divide each scalar field value by, defaults to 10000
    
    Returns - The dataset as a list of DataPt objects
    
    '''
    mat = io.loadmat(filename)
    dataset = []
    for i in range(len(mat['nodes'])):
        data = get_graph(mat,i)
        dataset.append(data)

    sse = SSE(k = 50)
    for data in dataset:
        c = sse.cvec(data.sdf)
        n = np.shape(data.x)[0]
        cmat = np.tile(c,(n,1))
        data.x = np.concatenate((data.x, cmat),1)

    for data in dataset:
        c = sse.cvec(data.sdf)
        n = np.shape(data.x)[0]
        cmat = np.tile(c,(n,1))

        data.s = torch.tensor(data.x[:,2])[:,None] * 10
        data.x = torch.tensor(data.x[:,:2])
        geom = (data.sdf > 0)
        data.sse = torch.tensor(cmat)
        sdf = torch.tensor(data.sdf[None, None, :, :],dtype=torch.double) * 10
        geom = torch.tensor(geom[None, None, :, :],dtype=torch.double)
        data.sdf = torch.cat((sdf,geom), 1)
        data.y = torch.tensor(data.y) / scale
        
    return dataset


def get_split_indices(dataset, train_fraction = 0.8, seed = 0):
    '''
    get_split_indices: Given a dataset, randomly generates indices for testing and training
    
    dataset - The list of data points
    train_fraction - The fraction of points to use for training, defaults to 0.8
    seed - The seed for random number generation, defaults to 0
    
    Returns:
    - Indices of data points to use for training
    - Indices of data points to use for testing
    
    '''
    random.seed(seed)
    N = len(dataset)
    idxs = random.sample(range(N),N)
    idxs_tr = idxs[:int(train_fraction*N)]
    idxs_val = idxs[int(train_fraction*N):]
    return idxs_tr, idxs_val
