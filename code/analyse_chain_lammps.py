#!/usr/bin/env python

import sys
import os
import os.path

import argparse

parser = argparse.ArgumentParser()
parser.add_argument('dirs', type=str, nargs='+',
                    help='directories containing simulation files')
parser.add_argument('--rate', type=float, default=0.1)
parser.add_argument('--sites', type=int, default=1)
parser.add_argument('-N', type=int, default=10000)
args = parser.parse_args()

import numpy as np
from scipy.optimize import leastsq
from io import StringIO
import matplotlib.pyplot as plt

NNEIGH=3.25
fraction = float(args.sites)/float(args.N)

# Open lammps log file to extract thermodynamic observables
def from_log(logfile,i0,i1):
    return np.loadtxt(StringIO(u''.join(logfile[i0+1:i1])), unpack=True)

fitfunc = lambda p, t: 1*(1.-np.exp(-t*p[0]-p[1]))
errfunc = lambda p, t, y: fitfunc(p, t) - y

p_data = []
for d in args.dirs:
    logfile = open(os.path.join(os.getcwd(), d, 'log.lammps')).readlines()
    start_indices = [(i,l) for (i,l) in enumerate(logfile) if l.startswith('Time ')]
    stop_indices = [(i,l) for (i,l) in enumerate(logfile) if l.startswith('Loop time')]
    time, e_tot, temp, e_kin, e_vdw, e_bond, e_pot, press, rho, n_bonds, n_bonds_max, bonds = from_log(logfile, start_indices[-1][0], stop_indices[-1][0])
    time -= time[0]
    n_bonds += float(args.sites)/float(args.N)
    plt.plot(time, n_bonds)
    nmax = min(int(1./(args.rate*fraction)), len(time))
    nmax = len(time)
    p, success = leastsq(errfunc, [args.rate*NNEIGH*fraction, 0./args.rate], args=(time[:nmax], n_bonds[:nmax]))
    p_data.append(p)
    print p

plt.plot(time, 1*(1.-np.exp(-time*args.rate*NNEIGH*fraction)))
p_data = np.array(p_data)
print "fit rate", p_data.mean(axis=0)[0]
print "th. rate", args.rate*NNEIGH*fraction
plt.plot(time, fitfunc(p_data.mean(axis=0), time), 'k--')

plt.show()
