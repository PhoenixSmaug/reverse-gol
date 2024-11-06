# Reversed Game of Life with Integer Programming and SAT Solving

Conway's famous [Game of Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) is a cellular automaton with the following rules, where $N$ is the number of living neighbours:

```math
x_{t+1} = \begin{cases}
1, & \text{if } x_t = 1 \text{ and } (N = 2 \text{ or } N = 3) \quad \text{(survival)} \\1, & \text{if } x_t = 0 \text{ and } N = 3 \quad \text{(birth)} \\0, & \text{otherwise} \quad \text{(death)}
\end{cases}
```

## Base Model

To model this as a system of linear inequalities suitable for integer programming and pseudo-Boolean SAT solving, we rewrite the rules into a single condition:
```math
x_{t+1} = 1 \, \iff \, 5 \leq x_t + 2 N \leq 7
```

It can be quickly verified that both systems are equivalent, but the latter is much easier to translate into pure linear inequalities.

### Forward Direction

We start by encoding that $x_{t+1} = 1 \implies 5 \leq x_t + 2 N \leq 7$ using the following two inequalities:
```math
5 x_{t + 1} \leq x_t + 2 N \leq 7 + 10 \cdot (1 - x_{t + 1}) 
```

So for $x_{t + 1} = 1$ we get our inequality from before and for $x_{t + 1} = 0$ we get $0 \leq x_t + 2 N \leq 17$, which is always fulfilled.

### Backwards Direction

Now we encode $x_{t+1} = 1 \impliedby 5 \leq x_t + 2 N \leq 7$ by the contraposition $x_{t+1} = 0 \implies \neg(5 \leq x_t + 2 N \leq 7) \iff x_t + 2 N \leq 4 \text{ or } x_t + 2 N \geq 8$. To encode the 'or', we introduce two auxillary binary variables, $m_t$ and $n_t$.
```math
x_t + 2 N \geq 8 n_t \quad \quad x_t + 2 N \leq 4 + 13 \cdot (1 - m_t) \quad \quad 1 - x_t \leq m_t + n_t
```
If $n_t = 1$, the first inequality ensures $x_t + 2 N \geq 8$ and if $m_t = 1$, the first inequality ensures $x_t + 2 N \leq 4$. And finally, the third inequality ensures that if 
$x_{t+1} = 0$ then $m_t = 1$ or $n_t = 1$, i.e. $\neg(5 \leq x_t + 2 N \leq 7)$ holds. If $x_{t + 1} = 1$ one can simply choose $n_t = m_t = 0$ and all three inequalities are fulfilled without restricting the values of $x_t$ and $N$.

## Additions

This completes the model construction, which is implemented as `modelGOL(width, height, timesteps)`, where width and height specify the bounding box. To ensure that our simulated cells always stay within the bounds, we additionally force all cells on the boundary to be dead for all timesteps.

### Reversed Search



### Oscillator Optimization

## External Solver Installation

### Google Or-Tools

### Exact


(c) Mia Muessig
