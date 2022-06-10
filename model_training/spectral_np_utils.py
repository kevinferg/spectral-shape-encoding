import numpy as np
import scipy
from scipy import linalg


def generate_laplacian(edges, edge_weights):
    '''
    generate_laplacian: Generate a weighted Laplacian matrix for a graph
    
    edges - Array with 2 columns representing 1-directional edge pairs:
    [Index of 'from' node,   Index of 'to' node]
    edge_weights - Array of edge weights for each one-directional pair in 'edges'

    Returns
    - NxN Laplacian matrix for the graph, where N is the largest index seen in 'edges'
    '''
    
    pairs = (edges[0].astype(int),edges[1].astype(int))
    L = scipy.sparse.csr_matrix((-edge_weights,pairs)).tolil()
    rows,_ = np.shape(L)
    for i in range(rows):
        L[i,i] = -np.sum(L[i,:])
        
    # Currently returns the dense matrix for simplicity:
    return L.todense()


def norm_sym_laplacian(xy_data, sigma=1):
    '''
    generate_laplacian: Generate a normalized symmetric Laplacian matrix for a graph with nodes in 2D
    All pairwise distances are computed efficiently using np.outer()
    
    xydata - Array of coordinates with 2 columns: [x-coordinate, y-coordinate]
    sigma - Approximate standard deviation of distances between nodes

    Returns
    - NxN Laplacian matrix for the graph, where N is the largest index seen in 'edges'
    '''

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


def get_eigs(L, ne = None):
    '''
    get_eigs: Calculate the normalized eigenvectors (and eigenvalues) of a matrix L
    
    L - The matrix for which to compute eigenvectors
    ne - The number of eigenvectors to return, beginning with the
    smallest (optional, returns all eigenvectors by default)
    
    Returns
    - E, the eigenvector matrix
    - w, the eigenvalues corresponding to eigenvectors in the columns of E
    '''
    
    if ne is None:
        w, v = scipy.linalg.eigh(L)
    else:
        w, v = scipy.linalg.eigh(L,subset_by_index=[0,ne-1])
    w,v = np.real(w),np.real(v)
    
    E = v/np.linalg.norm(v,axis=1).reshape(-1,1)
    return E, w


def pseudoinverse(E):
    '''
    pseudoinverse: Computes the Moore-Penrose (left) inverse of a matrix
    
    E - The matrix to invert (a 2D array)
    
    Returns
    - The pseudoinverse of 'E'
    '''   
    
    Einv = np.linalg.inv(E.T @ E) @ E.T
    return Einv;


def get_cvec(E, field):
    '''
    get_cvec: Computes the coefficients c that minimize the squared error resulting
    from reconstructing a scalar field f as the product (E c)
    That is, c minimizes the expression: || E c - f ||
    
    E - Eigenvector matrix, columns are eigenvectors
    f - Scalar field, same length as each column of 'E'
    
    Returns
    - The vector of coefficients such that (E c) approximates the input field
    '''
    
    Einv = pseudoinverse(E)
    field = field.reshape(-1,1)
    c = Einv @ field
    return c


class SSE():
    '''
    This class computes a Spectral Shape Encoding for a 2D Signed Distance Field
    
    n - Number of rows/columns of the (square) SDF matrix
    res - Number of rows/colums to sample for computing the SSE
    k - Number of spectral coefficients to use for computing spectral coefficients
    lb - x (or y) coordinate of the southwest-most point on the SDF matrix
    ub - x (or y) coordinate of the northeast-most point on the SDF matrix

    get_cvec(sdf) returns the coefficient vector 'c' to reconstruct 'sdf'
    '''
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
        
        self.L = norm_sym_laplacian(np.concatenate((self.xp.reshape(-1,1),self.yp.reshape(-1,1)),axis=1), 1)
        self.E, self.w = get_eigs(self.L, k)

    def cvec(self, sdf):
        z = sdf[np.ix_(self.xi, self.yi)]
        c = get_cvec(self.E, z).flatten()
        return c
