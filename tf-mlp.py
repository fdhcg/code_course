
#%%
#多层感知机
import tensorflow as tf
INPUT_NODE=2
OUTPUT_NODE=1
epoch=1000
LAYER1_NODE=3
learning_rate=0.01


#%%
def inference(input_tensor,weights1,biases1,weights2,biases2):
    layer1=tf.nn.relu(tf.matmul(input_tensor,weights1)+biases1)
    return tf.matmul(layer1,weights2)+biases2
def train():
    x=tf.placeholder(tf.float32,shape=(None,INPUT_NODE),name='x-input')
    y_=tf.placeholder(tf.float32,[None,OUTPUT_NODE],name='y-input')
    #x=[[1.,1.],[1.,-1.],[-1.,1.],[-1.,-1.]]
    #y_=[[1.],[-1.],[-1.],[1.]]
    weights1=tf.Variable(tf.truncated_normal([INPUT_NODE,LAYER1_NODE],stddev=1))
    biases1=tf.Variable(tf.constant(0.,shape=[LAYER1_NODE]))
    weights2=tf.Variable(tf.truncated_normal([LAYER1_NODE,OUTPUT_NODE],stddev=1))
    biases2=tf.Variable(tf.constant(0.,shape=[OUTPUT_NODE]))
    global_step=tf.Variable(0,trainable=False)
    y=inference(x,weights1,biases1,weights2,biases2)
    loss=tf.reduce_mean((y-y_)**2)
    train_step=tf.train.GradientDescentOptimizer(learning_rate).minimize(loss)
    with tf.Session() as sess:
        tf.global_variables_initializer().run()
        a=[[1.,1.],[1.,-1.],[-1.,1.],[-1.,-1.]]
        b=[[1.],[-1.],[-1.],[1.]]
        #test_feed={x:[[1,1],[1,-1],[-1,1],[-1,-1]],y_:[1,-1,-1,1]}
        for i in range(1,epoch+1):
            if  i % 100==0:
                print(str(i)+"th")
                print(sess.run(y,feed_dict={x:a}))
            sess.run(train_step,feed_dict={x:a,y_:b})#,feed_dict=validate_feed
            
            
train()
            
    


#%%



