import matplotlib.pyplot as plt
import numpy as np

plt.style.use('_mpl-gallery-nogrid')

with open('input.txt') as f:
    array = []
    for line in f: # read rest of lines
        array.append([int(x) for x in line.split()])

print(array)

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

