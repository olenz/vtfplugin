# Python script to generate radius data
import random

N = 1000
timesteps = 10
L = 30.0
min_radius = 0.5
max_radius = 2.0

print("atom 0:%d name O" % (N-1))
print("pbc %f %f %f" % (L, L, L))

for timestep in range(timesteps):
    print "timestep"
    for pid in range(N):
        print "%f %f %f %f" % (random.uniform(0.0,L), 
                               random.uniform(0.0,L), 
                               random.uniform(0.0,L), 
                               random.uniform(min_radius, max_radius)
                               )

