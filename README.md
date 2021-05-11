# Embedding Visualizer for IPE

[IPE](http://ipe.otfried.org/) is an extensible drawing editor software specially targeted at making figures for inclusion into LaTeX documents, as well as multi-page PDF presentations. This repository contains a small extension of IPE, a so-called _ipelet_. The ipelet in this repository aims at provinding an automatic tool for drawing _linear_ arrangements of graphs, also called embeddings.

## Main functionalities and purposes

This ipelet is a tool aimed at easing the process of drawing and manually editing linear arrangements of graphs. It can draw a graph from a `head vector` input and also from an `edge list`. Vertices can be mapped to positions indicated by their indices, or indicated by an arrangement function and/or an inverse arrangement function. Users can also label the vertices using math-text, and calculate metrics on the linear arrangement.

Users will find a complete guide at [this ipelet's wiki](https://github.com/lluisalemanypuig/ipe.embedviz/wiki). Here is a screenshot of the main dialog:

![](figures/main_dialog.png)

and a few examples of what it can do:

![](figures/metric-D-linear-tree-arrangement.png)

![](figures/star-labelled-nonoverlapping.png)

![](figures/star-labelled-greek.png)

## Installing

Copy all the `.lua` files into your ipelet directory. In Ubuntu, this is `~/.ipe/ipelets/`. Visit the home webpage of IPE for more information.

## History of changes

### 17th April 2021

- Implemented a better automatic spacing that takes into account all the dimensions of a text object, namely, its height, width and depth. **Only available on IPE 7.2.24 or newer.**

### 4th April 2021

- Implemented a first approach to a better vertical alignment of the arrangements. Waiting for the next release of IPE to be able to retrieve the height and depth of a text object.

### 28th March 2021

- Added more slots in the dialog for arrangements. Now users can draw up to 4 arrangements for the same graph without having to open the ipelet as many times as arrangements they want to draw.

### 27th March 2021

- Moved usage guide from this README to the brand new wiki for [this ipelet](https://github.com/lluisalemanypuig/ipe.embedviz/wiki).

### 21st March 2021

Renamed 'linear sequence' by 'head vector' and added new features:
- indicate vertex labels in a separate input text box. This works even for head vectors.
- modify the arrangement of a head vector by specifying a linear arrangement or an inverse linear arrangement.

### 3rd February 2021

- Split the main file `embedding_visualizer.lua` into several files, each starting with `ev_`.

### 31st January 2021

- Extended the Ipelet to apply an automatic spacing between the labels of the vertices.
- Updated the examples and added new ones.

### 30th December 2020

- Extended Ipelet to admit linear sequences.
- Uploaded new examples (of the new feature) and updated old examples.
- Code is now substantially better documented.

### 6th October 2020

- The objects created (marks, arcs, labels, ...) are selected to ease future manipulations when several arrangements are to be added to the document.

### 5th October 2020

- Display markers as the vertices of the graph.
- Extended the format of input strings.

### 1st October 2020

- Extended the ipelet to admit two diferent representations of a linear arrangement. The actual linear arrangement and the inverse linear arrangement (the so far so-called sequence).
- Fixed bugs (in the first extension).
- Allow users to choose the x offset.
- In case the arrangement was given (not the inverse), add the labels of the positions at the below the vertices.

### 30th September 2020

- Extended the ipelet to accept string and character values for the description of the graph and the embedding.
- Change label's text to say "Sequence" instead of "Embedding".

### 29th September 2020

- Created repository with first version of the ipelet.
