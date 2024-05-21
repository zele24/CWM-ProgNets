# !/usr/bin/python3
import numpy as np
import matplotlib.pyplot as plt

# parameters to modify
filename="iperf3_1.data"
label='bandwidth'
xlabel = 'Time (s)'
ylabel = 'Sample Bandwidth'
title='iperf3 bandwidth test'
fig_name='iperf3_1.png'
bins=100 #adjust the number of bins to your plot


t = np.loadtxt(filename, delimiter=" ", dtype="float")



numbList = []
for i in range(0,10):
	numbList.append(i+0.5)   #Because the data is between seconds, I'll plot the average value of that time range
	

plt.plot(numbList, t, label=label)  # Plot some data on the (implicit) axes.
#Comment the line above and uncomment the line below to plot a CDF
#plt.hist(t[:,1], bins, density=True, histtype='step', cumulative=True, label=label)

plt.xlabel(xlabel)
plt.ylabel(ylabel)
plt.title(title)
plt.legend()
plt.savefig(fig_name)
plt.show()
