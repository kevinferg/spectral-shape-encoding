import numpy as np
import torch


def smoothstep(a0, a1, w):
    return (a1 - a0) * (3.0 - w * 2.0) * w * w + a0

def linstep(a0, a1, w):
    return (a1-a0) * w + a0


def tensor_interp2d(grid, pts, epsilon = 1e-9):
    ''' 
    tensor_interp: interpolates a PyTorch tensor at the x-y coordinates requested
    
    grid - the array of values to interpolate, first 2 dimensions are for varying x and y,
           the last dimension has the values
    pts - A tensor of the x-y coordinates to get interpolated values at.
          0th dimension is points, 1st dimension is [xval, yval]
          The coordinates should be scaled between [0,0] and [1,1], corresponding to corners of 'grid'
    epsilon - A tolerance for making sure values do not exceed the allowable range
    
    Returns - tensor with number of rows equal to number of points, and columns containing the interpolated values
    '''
    
    pts = pts.view(-1,2)
    pts = pts.clip(min = torch.tensor(epsilon), max = torch.tensor(1 - epsilon))
    size = np.shape(grid)
    grid = torch.transpose(grid,1,2)
    if 2 == len(size):
        grid = grid[None,:,:]
    rows, columns = size[1], size[2]
    
    x, y = ((pts[:,0])*(columns-1)), ((pts[:,1])*(rows-1))
    
    x_f, x_i = np.modf(x)
    y_f, y_i = np.modf(y)
    
    x_f = x_f.view(1,-1)
    y_f = y_f.view(1,-1)
    x_i = x_i.long()
    y_i = y_i.long()

    
    
    bottom = smoothstep(grid[:, x_i, y_i],     grid[:, x_i + 1, y_i],     x_f)
    top    = smoothstep(grid[:, x_i, y_i + 1], grid[:, x_i + 1, y_i + 1], x_f)
    
    left   = smoothstep(grid[:, x_i, y_i],     grid[:, x_i, y_i + 1],     y_f)
    right  = smoothstep(grid[:, x_i + 1, y_i], grid[:, x_i + 1, y_i + 1], y_f)
    
    vals = 0.5 * smoothstep(left, right, x_f) + 0.5 * smoothstep(bottom, top, y_f)

    return torch.transpose(vals, 0, 1)