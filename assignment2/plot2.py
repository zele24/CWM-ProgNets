# !/usr/bin/python3
import numpy as np
import matplotlib.pyplot as plt

# parameters to modify
filename="ping_2_delin.data"
label='Ping speed'
xlabel = 'Ping number'
ylabel = 'Time taken (ms)'
title='Ping speed pi to lab'
fig_name='pi_to_lab_10x_0.2s_CDF.png'
bins=100 #adjust the number of bins to your plot


t = np.loadtxt(filename, delimiter=" ", dtype="float")

#plt.plot(t[:,0], t[:,1], label=label)  # Plot some data on the (implicit) axes.

#Comment the line above and uncomment the line below to plot a CDF
plt.hist(t[:,1], bins, density=True, histtype='step', cumulative=True, label=label)

plt.xlabel(xlabel)
plt.ylabel(ylabel)
plt.title(title)
plt.legend()
plt.savefig(fig_name)
plt.show()
