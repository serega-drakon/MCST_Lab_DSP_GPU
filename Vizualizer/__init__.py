import matplotlib.pyplot as plt
import numpy as np

plt.style.use('_mpl-gallery-nogrid')

array = []
files = ['bank 0.txt', 'bank 1.txt', 'bank 2.txt', 'bank 3.txt', 'bank 4.txt',
         'bank 5.txt', 'bank 6.txt', 'bank 7.txt', 'bank 8.txt', 'bank 9.txt',
         'bank10.txt', 'bank11.txt', 'bank12.txt', 'bank13.txt', 'bank14.txt',
         'bank15.txt']
dir = '../Test/'
for fname in files:
    with open(dir + fname) as f:
        for line in f: # read rest of lines
            array.append([int(x, 16) for x in line.split()])

#n = 32
# make data
#X, Y = np.meshgrid(np.linspace(-n, n, 64), np.linspace(-n, n, 64))
#Z = (1 - X/2 + X**5 + Y**3) * np.exp(-X**2 - Y**2)
Z = array
# plot
fig, ax = plt.subplots()

#ax.imshow(Z, cmap='gray', vmin=0, vmax=255)

ax.imshow(Z)
plt.show()

