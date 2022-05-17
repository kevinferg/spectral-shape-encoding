import numpy as np

import torch
import torch.nn.functional as F
from torch import nn, optim


from data_loading import *
from pytorch_utils import *
import time


class Net(torch.nn.Module):
    def __init__(self, dims):
        super(Net, self).__init__()
        self.layers = torch.nn.ModuleList()
        self.dims = dims
        for i in range(len(self.dims)-1):
            self.layers.append(torch.nn.Linear(self.dims[i], self.dims[i+1]))

    def forward(self, x):
        for i in range(len(self.layers)):
            x = self.layers[i](x)
            if i+1 < len(self.layers):
                x = F.relu(x)
        return x


class SSENet(torch.nn.Module):
    def __init__(self, num_filters = 16, num_sse = 50, pool_size = 8, kernel_size = 5, mlp_size=(128, 128, 96)):
        super(SSENet, self).__init__()
        self.pool = nn.AvgPool2d(pool_size, stride=pool_size)
        self.conv = nn.Conv2d( 2,  num_filters, kernel_size, padding = int((kernel_size-1)/2))       
        self.combine = Net((3 + num_filters + num_sse, *mlp_size, 1))
        self = self.double()
        
    def forward(self, data):
        x = data.x
        s = data.s
        sse = data.sse
        sdf0 = self.pool(data.sdf)
        sdf0 = self.conv(sdf0)
        x1 = tensor_interp2d(torch.squeeze(sdf0), x, 0.0001)
        x = torch.cat((x,s,sse,x1),1)
        x = self.combine(x)
        return x
    
    def filters(self, data):
        # Apply convolutional filters and return local feature maps
        x = data.x
        s = data.s
        sse = data.sse
        sdf0 = self.pool(data.sdf)
        sdf0 = self.conv(sdf0)
        return sdf0
    
    def count_parameters(self):
        return sum(p.numel() for p in self.parameters() if p.requires_grad)
    


    
class SSENetCustom(torch.nn.Module):
    def __init__(self, which_inputs, 
                 num_filters = 16, num_sse = 50, pool_size = 8, kernel_size = 5, mlp_size=(128, 128, 96)):
        super(SSENetCustom, self).__init__()
        
        self.use_xyd = which_inputs[0]
        self.use_local = which_inputs[1]
        self.use_global = which_inputs[2]
        
        if self.use_local:
            self.pool = nn.AvgPool2d(pool_size, stride=pool_size)
            self.conv = nn.Conv2d( 2,  num_filters, kernel_size, padding = int((kernel_size-1)/2))
        
        n_in = 3 * self.use_xyd + num_filters * self.use_local + num_sse * self.use_global
        
        self.combine = Net((n_in, *mlp_size, 1))
        self = self.double()
        
    def forward(self, data):
        x = data.x
        ins = []
        if self.use_xyd:
            s = data.s
            ins.append(x)
            ins.append(s)
        if self.use_global:
            sse = data.sse
            ins.append(sse)
        if self.use_local:
            sdf0 = self.pool(data.sdf)
            sdf0 = self.conv(sdf0)
            x1 = tensor_interp2d(torch.squeeze(sdf0), x, 0.0001)
            ins.append(x1)
            
        
        x = torch.cat(ins,1)
        x = self.combine(x)
        return x
    
    def count_parameters(self):
        return sum(p.numel() for p in self.parameters() if p.requires_grad)



def train_model(model, dataset, idxs_tr, idxs_val, epochs = 50, lr = 0.001, print_progress = True):
    ''' 
    train_model: Trains a Pytorch model
    
    model - the model to train
    
    dataset - the data on which to train the model
    
    idxs_tr - the indices of 'dataset' to be used for training data
    
    idxs_val - the indices of 'dataset' to be used for validation
    
    epochs - The number of epochs to train
    
    lr - The learning rate (for Adam optimizer)
    
    Returns:
    - The model
    - A list of average training loss for each epoch
    - A list of average validation loss for each epoch
    - An approximate time to complete all epochs of training, in seconds
    '''
    
    loss_hist = []
    val_hist = []
    
    start_time = time.time() # There are more accurate ways of measuring time, but this should be sufficient

    opt = optim.Adam(params = model.parameters(),lr=lr)

    numpoints = len(dataset)
    indices = range(numpoints)

    for epoch in range(epochs):
        indices = random.sample(idxs_tr,len(idxs_tr))
        this_loss = []
        loss_val = []
        for k,i in enumerate(indices):
            data = dataset[i]

            out = model(data)
            loss = F.mse_loss(out, data.y)
            this_loss.append(loss.item())

            opt.zero_grad()
            loss.backward()
            opt.step()

            idx = random.sample(idxs_val, 1)[0]
            loss_val.append(F.mse_loss(model(dataset[idx]), dataset[idx].y).item())
            if print_progress:
                print("\r[%-25s]       \r" %("========================="[24-int(25*k/800):]),end="",flush=True)

        loss_hist.append(np.mean(np.array(this_loss)))
        val_hist.append(np.mean(np.array(loss_val)))
        if print_progress:
            print(f"Epoch {epoch} of {epochs}... Train loss: {loss_hist[-1]}      Test loss: {val_hist[-1]}")

    end_time = time.time()
    total_time = end_time - start_time
    if print_progress:
        print(total_time/60, "minutes")
    
    return model, loss_hist, val_hist, total_time
    