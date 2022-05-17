import numpy as np
import scipy
from scipy import io
import torch

from spectral_np_utils import *
import random

class DataPt:
    def __init__(self, x = None, y = None, sdf = None):
        self.x = x
        self.y = y
        self.sdf = sdf

        
def get_graph(mat,index):
    nodes = mat['nodes'][index,0].T
    elems = mat['elem'][index,0].T-1
    stress = mat['stress'][index,0]
    dt = mat['dt'][index,0]
    sdf = mat['sdf'][index][0].T
    data = DataPt(x=np.concatenate((nodes,dt),axis=1), y=stress, sdf=sdf)
    return data


def load_matlab_dataset(filename, scale = 10000):
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
    random.seed(seed)
    N = len(dataset)
    idxs = random.sample(range(N),N)
    idxs_tr = idxs[:int(train_fraction*N)]
    idxs_val = idxs[int(train_fraction*N):]
    return idxs_tr, idxs_val