# !/usr/bin/python3
import numpy as np
import matplotlib.pyplot as plt

# parameters to modify
filename="ping_5_0.0001_delin.data"
label='Ping speed'
xlabel = 'Ping number'
ylabel = 'Cumulative Frequency'
title='Ping speed'
fig_name='ping_5_3_graph.png'
bins=100 #adjust the number of bins to your plot


t = np.loadtxt(filename, delimiter=" ", dtype="float")

numbList = []
for i in range(0,4000):
	numbList.append(i)

#plt.plot(numbList, t, label=label)  # Plot some data on the (implicit) axes.

#Comment the line above and uncomment the line below to plot a CDF
plt.hist(t, bins, density=True, histtype='step', cumulative=True, label=label)

plt.xlabel(xlabel)
plt.ylabel(ylabel)
plt.title(title)
plt.legend()
plt.savefig(fig_name)
plt.show()
