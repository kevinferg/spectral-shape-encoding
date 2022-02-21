# Scalar Field Prediction on Topologically-Varying Graphs using Spectral Shape Encoding

#### Authors
Kevin Ferguson and Levent Burak Kara, Carnegie Mellon University

### Abstract
Scalar fields, such as stress or temperature fields, are often calculated in shape optimization and design problems in engineering. For complex problems where shapes have varying topology and cannot be parametrized, data-driven scalar field prediction can be faster than traditional finite-element methods. However, current data-driven techniques to predict scalar fields are limited to a fixed grid domain, instead of arbitrary graph/mesh structures. In this work, we propose a method to predict scalar fields on meshes of arbitrary refinement and topology. It uses pre-computed features that capture shape geometry on a local and global scale as input to a multilayer perceptron to predict solutions to partial differential equations on graph data structures. The proposed set of global features is a vector that concisely represents the entire mesh as a spectral shape encoding. The model is trained on finite-element von Mises stress fields, and once trained it can estimate stress values at each node on any input mesh. Two shape datasets are investigated, and the model demonstrates decent performance on both, with median adjusted R-squared values of 0.68 and 0.76. We also demonstrate the model's performance on a temperature field in a conduction problem, where its predictions have median adjusted R-squared values of 0.98 and 0.97. By predicting from a simple, yet rich, set of mesh features, our method provides a potential flexible alternative to finite-element simulation in engineering design contexts.


### Usage

#### Dataset generation
Dataset generation is done in MATLAB using the PDE Toolbox. See [dataset_generation/dataset_generation_info.txt](dataset_generation/dataset_generation_info.txt) for details on generating data. 


The datasets also can be downloaded from this [Google Drive link](https://drive.google.com/file/d/1q3YjUbg9SZ3rF09kn7SZqJqHjODUEHuq/view?usp=sharing).

#### Model training
Model creation/training code will be added shortly.

### Acknowledgments
This research was funded by Air Force Research Laboratory S111068002. We would like to thank James Hardin and Andrew Gillman for their insightful feedback and ideas throughout this project.

