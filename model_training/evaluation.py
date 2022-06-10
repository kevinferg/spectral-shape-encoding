import numpy as np
import matplotlib.pyplot as plt

import torch

from data_loading import *
from pytorch_utils import *

def get_r2(a,b):
    ''' 
    get_r2: Computes an R-squared value to evaluate the goodness
    of fit between two nd-arrays
    
    a - The ground-truth data
    b - The predicted data
    
    Returns
    - The R2 value
    '''
    N = len(a)
    SS_tot = np.sum((b-np.mean(b))**2)
    SS_res = np.sum((a-b)**2)
    R2 = 1-SS_res/SS_tot
    return R2

def adj_r2(a,b,nf=1): 
    ''' 
    adj_r2: Computes an adjusted R-squared value to evaluate the goodness
    of fit between two nd-arrays, adjusted for the number of predictors used
    
    a - The ground-truth data
    b - The predicted data
    nf - The number of features used to make the prediction in 'b'
    
    Returns
    - The adjusted R2 value
    '''
    R2 = get_r2(a, b)
    R2 = 1-(1-R2)*(N-1)/(N-nf-1)
    return R2

def eval_model(model,data):
    ''' 
    evaluate_model: Runs a model and computes the R-squared value on a single data point
    
    model - The model to evaluate
    data - the data point
    
    Returns
    - The R2 value from using 'model' to predict the field in 'data'
    '''

    pred = model(data).detach().numpy().flatten()
    gt = data.y.detach().numpy().flatten()

    return get_r2(pred, gt)

def evaluate_all_data(model, wss, idxs_tr, idxs_val, oss):
    ''' 
    evaluate_all_data: Runs a model and computes the R-squared value on every point in the
    training, testing, and out-of-sample sets
    
    model - The model to evaluate
    wss - Within sample set data
    idxs_tr - indices of wss in the training set
    idxs_val - indices of wss in the validation/testing set
    oss - Out-of-sample set data
    
    Returns
    - Array of R2 values on training data
    - Array of R2 values on testing data
    - Array of R2 values on out-of-sample-set data
    '''
    
    vals = []
    for i in idxs_tr:
        val = eval_model(model,wss[i])
        vals.append(val)
    vals1 = np.array(vals)


    vals = []
    for i in idxs_val:
        val = eval_model(model,wss[i])
        vals.append(val)
    vals2 = np.array(vals)

    vals = []
    for i in range(len(oss)):
        val = eval_model(model,oss[i])
        vals.append(val)
    vals3 = np.array(vals)
    
    return vals1, vals2, vals3

def plot_boxes(train_evals, test_evals, oss_evals, lims = [-0.25, 1], filename = None):
    ''' 
    plot_boxes: Creates a box-and-whisker plot for the evaluations generated in evaluate_all_data()
    
    train_evals - Array of R2 values on training data
    test_evals - Array of R2 values on test data
    oss_evals - Array of R2 values on out-of-sample-set data
    lims - The y-axis limits of the plot
    filename - (Optional) The name of the file to save the plot as an image
    
    Returns
    - If 'filename' argument is specified, saves an image to 'filename', otherwise displays the figure
    '''
    plt.figure(figsize=(6,3.4), dpi=175)
    plt.boxplot([train_evals, test_evals, oss_evals], positions=[1,2,3])

    plt.plot([.5,3.5],[0,0],'k-',linewidth=0.5)
    plt.xticks([1,2,3],['Training, N='+str(len(train_evals)),'Testing, N='+str(len(test_evals)),'Out-of-sample, N='+str(len(oss_evals))])
    plt.ylabel('R-Squared')
    plt.ylim(lims)

    if filename is not None:
        plt.savefig(filename, bbox_inches = "tight")
        plt.close()
    else:
        plt.show()

def plot_compare(model, data, filename = None,s = 10, m = 1.8):
    ''' 
    plot_compare: Makes a set of plots for comparing a model's prediction on a data point with
    the ground-truth, as per the following:
    Subplot 1: Visualization of the predicted scalar field value at every node
    Subplot 2: Visualization of the ground-truth scalar field value at every node
    Subplot 3: Visualization of the absolute difference between the predicted and ground-truth fields
    Subplot 4: Predicted-vs-actual plot for the model's predictions across all nodes
    
    model - The model to use for prediction
    data - The data point on which to visualize the results
    filename - (Optional) The name of the file to save the plot as an image
    s - The size of each node
    m - The maximum value of the theoretical best line drawn on Subplot 4
    
    Returns
    - If 'filename' argument is specified, saves an image to 'filename', otherwise displays the figure
    
    '''
    
    plt.figure(figsize=(12,4),dpi=180)
    title_height = 0.86
    cbar_shrink = 0.9
    cbar_pad = -0.1
    
    
    x = data.x[:,0].detach().numpy()
    y = data.x[:,1].detach().numpy()
    pred = model(data)
    pred = pred.detach().numpy().flatten()
    gt = data.y.detach().numpy().flatten()
    
    l1 = 0
    l2 = ((torch.max(pred)+0)/2).item()
    l3 = torch.max(pred).item()
    
    l11 = 0
    l12 = ((torch.max(data.y)+0)/2).item()
    l13 = torch.max(data.y).item()
    
    tick0 = 0
    tick2 = np.round(np.max(np.abs(pred-gt)),3)
    tick1 = (tick0 + tick2)/2

    ### Subplot 1 - Prediction:
    
    plt.subplot(1,4,1)
    plt.scatter(x, y, c=pred,s=s,cmap='jet',vmin = 0)
    plt.title('Prediction',y=title_height)
    plt.axis('equal')
    plt.axis('off')
    
    plt.set_cmap('jet')
    bar1 = plt.colorbar(shrink=cbar_shrink,location='bottom',pad=cbar_pad,ticks=[0,l2,l3])
    bar1.ax.set_xticklabels([0,np.round(l2,3),np.round(l3,3)])

    ### Subplot 2 - Ground Truth:
    
    plt.subplot(1,4,2)
    plt.scatter(x, y, c=gt,s=s,cmap='jet',vmin = 0)
    plt.title('Ground Truth',y=title_height)
    plt.axis('equal')
    plt.axis('off')
    
    plt.set_cmap('jet')
    bar2 = plt.colorbar(shrink=cbar_shrink,location='bottom',pad=cbar_pad,ticks=[l11,l12,l13])
    bar2.ax.set_xticklabels([round(l11,3),np.round(l12,3),np.round(l13,3)])
    
    ### Subplot 3 - Error:

    ax = plt.subplot(1,4,3)
    plt.scatter(x, y, c=np.abs(pred - gt),s=s,cmap='jet',vmin = 0,vmax=tick2)
    plt.title('Absolute Difference',y=title_height)
    plt.axis('equal')
    plt.axis('off')
    plt.set_cmap('jet')

    bar3 = plt.colorbar(shrink=cbar_shrink,location='bottom',pad=cbar_pad,ticks=[tick0, tick1, tick2])
    bar3.ax.set_xticklabels([tick0, tick1, tick2])

    ### Subplot 4 - R Squared:
    
    ax = plt.subplot(1,4,4)
    plt.scatter(gt,pred,c='b')
    plt.plot([0,m],[0,m],'r-')
    plt.xlabel('Ground Truth')
    plt.ylabel('Prediction')
    plt.title(f"R2: {np.round(get_r2(pred, gt),3)}")
    plt.xlim([0,m])
    plt.ylim([0,m])
    plt.yticks(plt.xticks()[0])
    plt.axis('square')
    
    ###
    
    plt.tight_layout()
    plt.subplots_adjust(left=None, bottom=None, right=None, top=None, wspace=0.15, hspace=None)
    
    pos1 = ax.get_position() # get the original position 
    pos2 = [pos1.x0 + 0.017, pos1.y0 + 0.06,  pos1.width * 0.9, pos1.height * 0.9] 
    ax.set_position(pos2) # set a new position
    
    if filename is not None:
        plt.savefig(filename, bbox_inches = "tight")
        plt.close()
    else:
        plt.show()
