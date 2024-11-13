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

Now we encode $x_{t+1} = 1 \impliedby 5 \leq x_t + 2 N \leq 7$ by the contraposition $x_{t+1} = 0 \implies x_t + 2 N \leq 4 \text{ or } x_t + 2 N \geq 8$. To encode the 'or', we introduce two auxillary binary variables, $m_t$ and $n_t$.
```math
x_t + 2 N \geq 8 n_t \quad \quad x_t + 2 N \leq 4 + 13 \cdot (1 - m_t) \quad \quad 1 - x_t \leq m_t + n_t
```
If $n_t = 1$, the first inequality ensures $x_t + 2 N \geq 8$ and if $m_t = 1$, the first inequality ensures $x_t + 2 N \leq 4$. And finally, the third inequality ensures that if 
$x_{t+1} = 0$ then $m_t = 1$ or $n_t = 1$, i.e. $\neg(5 \leq x_t + 2 N \leq 7)$ holds. If $x_{t + 1} = 1$ one can simply choose $n_t = m_t = 0$ and all three inequalities are fulfilled without restricting the values of $x_t$ and $N$.

## Additions

This completes the model construction, which is implemented as `modelGOL(width, height, timesteps)`, where width and height specify the bounding box. To ensure that our simulated cells always stay within the bounds, we additionally force all cells on the boundary to be dead for all timesteps.

### Reversed Search

To run Game of Life backwards, we simply restrict $x_{end}$ as desired. If we want to have a board which becomes Donald Knuths example $7 \times 15$ board spelling out "LIFE" after 3 iterations, we can construct the model with `reversePlay(width, height, timesteps, cells)` and find a solution in 4.8s using the pseudo-Boolean SAT solver [Exact](https://gitlab.com/nonfiction-software/exact):

```math
\begin{matrix}
\text{Time } t=1 & \quad & \text{Time } t=2 & \quad & \text{Time } t=3 & \quad & \text{Time } t=4 \\
\begin{bmatrix}
. & . & . & X & . & . & . & X & . & . & . & X & . & X & . \
. & . & . & . & . & . & . & . & . & X & . & X & . & . & X \
X & X & X & . & X & . & . & X & X & . & . & . & X & X & . \
X & X & . & . & X & X & . & X & . & X & . & . & . & X & X \
. & . & X & . & X & . & X & . & X & . & X & . & X & . & . \
. & . & X & . & X & . & . & . & . & . & . & X & X & . & X \
X & . & X & . & X & . & X & . & X & X & . & . & . & X & . \
\end{bmatrix}
& \rightarrow &
\begin{bmatrix}
. & . & . & . & . & . & . & . & . & . & X & . & X & . & . \
. & X & X & X & . & . & . & X & . & . & X & X & . & . & X \
X & . & X & X & X & X & X & X & . & X & X & . & X & . & . \
X & . & . & . & X & . & . & . & . & X & . & X & . & . & X \
. & . & X & . & X & . & X & X & X & X & X & . & X & . & X \
. & . & X & . & X & . & . & . & X & . & X & X & X & . & . \
. & X & . & . & . & X & . & . & . & . & . & . & X & X & . \
\end{bmatrix}
& \rightarrow &
\begin{bmatrix}
. & . & X & . & . & . & . & . & . & . & X & . & . & . & . \
. & X & . & . & . & X & . & X & X & . & . & . & X & X & . \
X & . & . & . & . & X & X & X & . & X & . & . & X & X & . \
. & . & X & . & . & . & . & . & . & . & . & . & X & . & . \
. & X & . & . & X & . & . & X & . & . & . & . & X & . & . \
. & X & X & . & X & . & X & . & X & . & X & . & . & . & . \
. & . & . & . & . & . & . & . & . & . & . & . & X & X & . \
\end{bmatrix}
& \rightarrow &
\begin{bmatrix}
. & . & . & . & . & . & . & . & . & . & . & . & . & . & . \
. & X & . & . & . & X & . & X & X & X & . & X & X & X & . \
. & X & . & . & . & X & . & X & . & . & . & X & . & . & . \
. & X & . & . & . & X & . & X & X & . & . & X & X & . & . \
. & X & . & . & . & X & . & X & . & . & . & X & . & . & . \
. & X & X & X & . & X & . & X & . & . & . & X & X & X & . \
. & . & . & . & . & . & . & . & . & . & . & . & . & . & . \
\end{bmatrix}
\end{matrix}
```

It also only takes only 10.7s to prove that no starting pattern exists which forms the "LIFE" example after 4 instead of 3 iterations.

### Oscillator Optimization

To search for oscillators, i.e. patterns that repeat after a certain period, we need to add another binary auxiliary variable $o_t$ to our model. The equivalence $o_t = 1 \iff x_{t = 1} \neq x_t$ with:
```math
x_t - x_{t + 1} \leq o_t \quad \quad x_{t + 1} - x_t \leq o_t \quad \quad x_t + x_{t + 1} \geq o_t \quad \quad 2 - (x_t + x_{t + 1}) \geq o_t
```

Now we make sure that the patterns repeat after the period $p$ with $x_1 = x_{1 + p}$ for all tiles of the board and that they do not repeat earlier by adding $\sum_i \sum_j o_{t}(i, j) \geq 1$ for all $t \leq p$, i.e. at each time step the board differs from the start pattern by at least one tile. Finally we use the objective function $\sum_i \sum_j x_{p + 1}(i, j)$ to find the smallest possible oscillator.

As an example, we can look at period-3 oscillators, which are quite rare due to the binary nature of Game of Life. Again, using the Exact solver, we can prove that the following pattern called ‘Jam’ is indeed the smallest possible period-3 oscillator in a $7 \times 7$ bounding box, in just 424s. The CP-SAT solver included in Google's [OR-Tools](https://developers.google.com/optimization) can even do it in just 167s, while even commercial Integer Programming solvers like [Gurobi](https://www.gurobi.com/) take over 20 minutes.

```math
\begin{matrix}
\text{Time } t=1 & \quad & \text{Time } t=2 & \quad & \text{Time } t=3 & \quad & \text{Time } t=4 \\
\begin{bmatrix}
. & . & . & . & X & X & . \
. & . & . & X & . & . & X \
. & X & . & . & X & . & X \
. & X & . & . & . & X & . \
. & X & . & . & . & . & . \
. & . & . & . & X & . & . \
. & . & X & X & . & . & . \
\end{bmatrix}
& \rightarrow &
\begin{bmatrix}
. & . & . & . & X & X & . \
. & . & . & X & . & . & X \
. & . & X & . & X & . & X \
X & X & X & . & . & X & . \
. & . & . & . & . & . & . \
. & . & X & X & . & . & . \
. & . & . & X & . & . & . \
\end{bmatrix}
& \rightarrow &
\begin{bmatrix}
. & . & . & . & X & X & . \
. & . & . & X & . & . & X \
. & . & X & . & X & . & X \
. & X & X & X & . & X & . \
. & . & . & X & . & . & . \
. & . & X & X & . & . & . \
. & . & X & X & . & . & . \
\end{bmatrix}
& \rightarrow &
\begin{bmatrix}
. & . & . & . & X & X & . \
. & . & . & X & . & . & X \
. & X & . & . & X & . & X \
. & X & . & . & . & X & . \
. & X & . & . & . & . & . \
. & . & . & . & X & . & . \
. & . & X & X & . & . & . \
\end{bmatrix}
\end{matrix}
```

Using the Cube-and-Conquer SAT solver [treengeling](https://github.com/arminbiere/lingeling), we can also show in just 20 minutes that no period-5 oscillator can exist in a 7x7 bounding box, proving optimality of the [Fumarole](https://conwaylife.com/wiki/Fumarole) 7x8 period-5 oscillator.

## External Solver Installation

Since their installation can be quite tedious, you will find short installation instructions for the Exact Solver and the Or-Tools for Ubuntu here.

### Google Or-Tools

Install the required build tools:

```bash
sudo apt install build-essential lsb-release -y
sudo snap install cmake --classic
```

Download the binary [here](https://developers.google.com/optimization/install/cpp/binary_linux), then compile:
```bash
mkdir -p or-tools && tar -xzf or-tools_*.tar.gz --strip-components=1 -C or-tools && cd or-tools
```

```bash
make test
sudo cp bin/* /usr/local/bin
sudo cp -r lib/* /usr/local/lib
sudo cp -r share/* /usr/local/share
```

Now finally the CP-SAT solver can be used as:
```bash
solve --solver=sat --num_threads=16 --input=test.mps --sol_file=test.sol
```

### Exact

Install the required build tools:

```bash
sudo apt-get install build-essential libbz2-dev coinor-libcoinutils-dev libboost-all-dev -y
```

To compile the solver:

```bash
git clone https://gitlab.com/nonfiction-software/exact.git && cd exact
git submodule init && git submodule update
mkdir soplex_build && cd soplex_build
cmake ../soplex -DBUILD_TESTING="0" -DSANITIZE_UNDEFINED="0" -DCMAKE_BUILD_TYPE="Release" -DBOOST="0" -DGMP="0" -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS="0" -DZLIB="0"
make -j 8
sudo make install

cd ../build_debug && cmake .. -DCMAKE_BUILD_TYPE="Release" -Dsoplex="ON" -Dcoinutils="ON"
make -j 8
make install
```

Now finally the pseudo-Boolean SAT solver can be used as:

```bash
Exact test.mps
```

(c) Mia Muessig
