
# coding: utf-8

# a simple multi-layer perceptron model


import numpy as np
class MLP(object):
    def __init__(self,num_lay,num_node):
        self.num_lay=num_lay
        self.num_node=num_node
        self.w=np.random.rand(num_lay-1,num_node,num_node)
        self.b=np.random.rand(num_lay-1,num_node)
        self.node=np.random.rand(num_lay,num_node)
        self.f=lambda x:1.0/(1+np.exp(-x))
    def fp(self,data):
        for i in range(len(data)):
            self.node[0][i]=data[i]
        for i in range(1,self.num_lay-1):
            for j in range(self.num_node):
                self.node[i][j]=self.f(self.node[i-1].dot(self.w[i-1][j].T)+self.b[i-1][j])
        for j in range(self.num_node):
            self.node[self.num_lay-1][j]=(self.node[self.num_lay-2].dot(self.w[self.num_lay-2][j])+self.b[self.num_lay-2][j])
            print(self.node[self.num_lay-1][j])
    def bp(self,y):
        delta=0.1*(y-self.node[self.num_lay-1])
        for i in range(self.num_lay-1)[::-1]:
            self.b[i]+=delta
            delta_w=[x*(self.node[i]) for x in delta]
            delta=delta.dot(self.w[i])*self.node[i]*(1-self.node[i]) 
            self.w[i]+=delta_w
            
                
        




trainer=MLP(3,2)
#INPUT:O---O---O:OUTPUT
#        X   X
#INPUT:O---O---O:OUTPUT
#          |
#     HIDDEN LAYER
i=0
while i<10000:
    print("\n")
    
    trainer.fp([1,0])
    trainer.bp([1,1])
    trainer.fp([0,1])
    trainer.bp([1,1])
    trainer.fp([0,0])
    trainer.bp([-1,-1])
    trainer.fp([1,1])
    trainer.bp([-1,-1])
    i+=1



trainer.fp([0,0])
    

    

