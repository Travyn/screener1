#!/usr/bin/env python3

# Mark Agate

import pandas as pd
import datetime
import time
import matplotlib.pyplot as plt
import numpy as np
import tensorflow as tf
import scipy.optimize as spo

initial_investment = 1000

start = datetime.datetime(2015, 1, 1)
end = datetime.datetime(2017, 10, 25)

dates = pd.date_range(start, end)

df_dates = pd.DataFrame(index=dates)

spy = pd.read_csv("SPY.csv", index_col="Date", parse_dates=True)

spy = spy.rename(columns={'Adj Close':'SPY'})

df_adjClose = df_dates.join(spy["SPY"], how='inner')

df_adjClose = df_adjClose.dropna()

spyVol = pd.read_csv("SPY.csv", index_col="Date", parse_dates=True)
spyVol = spyVol.rename(columns={'Volume':'SPY'})
df_vol = df_dates.join(spyVol["SPY"], how='inner')
df_vol = df_vol.dropna()

symbols = ['TSLA', 'AAPL']

for symbol in symbols:
    df_temp = pd.read_csv("%s.csv" %symbol, index_col="Date", parse_dates=True)
    df_temp = df_temp.rename(columns={"Adj Close":symbol})
    df_adjClose = df_adjClose.join(df_temp[symbol])

    df_temp2 = pd.read_csv("%s.csv" %symbol, index_col="Date", parse_dates=True)
    df_temp2 = df_temp2.rename(columns={'Volume':symbol})
    df_vol = df_vol.join(df_temp2[symbol])

def compute_daily(df):
    '''
    daily_returns = df.copy() # copy of the data frame to match size and column names
    daily_returns[1:] = (df[1:]/df[:-1].values) - 1 # daily returns for row 1 onwards
    daily_returns.ix[0, :] = 0 # set daily returns for row zero to zero
    '''

    # with pandas
    daily_returns=(df/df.shift(1))-1
    if df.ndim > 1:
        daily_returns.iloc[0,:]=0 # Replace the nans
    else:
        daily_returns.iloc[0]=0

    return daily_returns

df_adjClose_normalized = df_adjClose/df_adjClose.iloc[0,:]

allocs = [0.33, 0.33, 0.34]
alloced = df_adjClose_normalized*allocs
pos_vals = alloced*initial_investment
port_val = pos_vals.sum(axis=1)
daily_returns = compute_daily(df_adjClose)
#df_adjClose.ndim
#port_val.ndim
port_val_daily_returns = compute_daily(port_val)
#sum_port_val_daily = port_val_daily_returns.sum(axis=1)

#----- Sharpe ratio calcluations -----#
cum_return = (port_val[-1]/port_val[0])-1
avg_daily_return = port_val_daily_returns.mean()
std_daily_return = port_val_daily_returns.std()
daily_rf = (1.0+0.1)**(1./252) - 1
S = ((avg_daily_return-daily_rf)/std_daily_return)**(1./252) # sharpe ratio annualized
print("Sharpe ratio: \n{}".format(S))

def sharpe(allocs, df_adjClose_normalized):
    alloced = df_adjClose_normalized*allocs
    pos_vals = alloced*initial_investment
    port_val = pos_vals.sum(axis=1)
    daily_returns = compute_daily(df_adjClose)
    port_val_daily_returns = compute_daily(port_val)

    cum_return = (port_val[-1]/port_val[0])-1
    avg_daily_return = port_val_daily_returns.mean()
    std_daily_return = port_val_daily_returns.std()
    daily_rf = (1.0+0.1)**(1./252) - 1
    S = ((avg_daily_return-daily_rf)/std_daily_return)**(1./252) # sharpe ratio annualized
    return S

allocs2 = [0.3, 0.3, 0.4]
S1 = sharpe(allocs2, df_adjClose_normalized)
print("S1: \n{}".format(S1))

def sharpeFun(allocs, initial_investment, df_adjClose_normalized):
    alloced = df_adjClose_normalized*allocs
    pos_vals = alloced*initial_investment
    port_val = pos_vals.sum(axis=1)
    daily_returns = compute_daily(df_adjClose)
    port_val_daily_returns = compute_daily(port_val)

    #cum_return = (port_val[-1]/port_val[0])-1
    avg_daily_return = port_val_daily_returns.mean()
    std_daily_return = port_val_daily_returns.std()
    daily_rf = (1.0+0.1)**(1./252) - 1
    S = -(((avg_daily_return-daily_rf)/std_daily_return)**(1./252)) # sharpe ratio annualized
    S
    return S

def optimizeSharpe(allocs, initial_investment, df_adjClose_normalized):
    cons = ({'type': 'eq',
            'fun': lambda allocs: np.sum(allocs) - 1})
    bnds = [(0, None,) for i in range(len(allocs))]
    optimalAllocs = spo.minimize(sharpeFun, allocs, args=(initial_investment,df_adjClose_normalized,),bounds=bnds, constraints=cons, method='SLSQP', options={'disp':True})

    return optimalAllocs

allocs = [0.2, 0.2, 0.6]

allocsNew = optimizeSharpe(allocs, initial_investment, df_adjClose_normalized)
allocsNewRound = np.round(allocsNew.x,2)
print('Optimum allocations: {}'.format(allocsNewRound))
print('SPY',symbols)
