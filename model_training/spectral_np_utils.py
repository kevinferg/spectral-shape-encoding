import numpy as np
import scipy
from scipy import linalg


def generate_laplacian(edges,edge_weights):
    # Columns of 'edges' are ~one-directional~ pairs in the graph
    # 'edge_weights' is an array of edge weights for each one-directional pair in 'edges'
    pairs = (edges[0].astype(int),edges[1].astype(int))
    L = scipy.sparse.csr_matrix((-edge_weights,pairs)).tolil()
    rows,_ = np.shape(L)
    for i in range(rows):
        L[i,i] = -np.sum(L[i,:])
        
    # Currently returns the dense matrix for simplicity:
    return L.todense()


def norm_sym_laplacian(xy_data,sigma=1):
    # 'data' has x-coords in column 0 and y-coords in column 1
    # sigma is standard deviation of distances between nodes
    n,_ = np.shape(xy_data)
    x = xy_data[:,0]
    y = xy_data[:,1]
    W = np.square((np.subtract.outer(x,x)))+np.square((np.subtract.outer(y,y)))
    W = np.exp(-W/sigma**2)
    D = np.sum(W,axis=0)
    d = np.diag(D**-.5)
    I = np.identity(n)
    L = I-d@W@d
    return L


def get_eigs(L,ne=None):
    if ne is None:
        w,v = scipy.linalg.eigh(L)
    else:
        w,v = scipy.linalg.eigh(L,subset_by_index=[0,ne-1])
    w,v = np.real(w),np.real(v)
    
    E = v/np.linalg.norm(v,axis=1).reshape(-1,1)
    return E,w


def pseudoinverse(E):
    Einv = np.linalg.inv(E.T @ E) @ E.T
    return Einv;


def get_cvec(E,field):
    Einv = pseudoinverse(E)
    field = field.reshape(-1,1)
    c = Einv @ field
    return c


class SSE():
    def __init__(self, n = 64, res = 16, k = 25, lb = 0, ub= 1):
        self.res = res
        self.ub = ub
        self.lb = lb
        self.n = n
        self.k = k
        
        xp = np.linspace(0,1,res)
        yp = np.linspace(0,1,res)
        
        self.xp, self.yp = np.meshgrid(xp, yp)
        span = ub-lb
        self.xi = ((xp-lb)/span*(n-1)).astype(int)
        self.yi = ((yp-lb)/span*(n-1)).astype(int)
        
        self.L = norm_sym_laplacian(np.concatenate((self.xp.reshape(-1,1),self.yp.reshape(-1,1)),axis=1),1)
        self.E, self.w = get_eigs(self.L,k)

        
    def cvec(self,sdf):
        z = sdf[np.ix_(self.xi, self.yi)]
        c = get_cvec(self.E, z).flatten()
        return c