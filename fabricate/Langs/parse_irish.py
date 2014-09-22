import copy
from pylab import *
from numpy import *


if False:
    out = open("Irish.txt", "w")
    times = open("Irish_orig.txt").readlines()
    now = 0
    for l in times:
        if '(' in l:
            l = l.split('(')[0]
        if ('-') in l:
            l = l.split('-')[0]
        l = l.strip()
        print >> out, '%02d:%02d' % (now / 60, now % 60), l.lower()
        now += 5
    out.close()
    print 'wrote', out.name
times = open("Irish_v5.txt").readlines()
sentences = [l[5:].split() for l in times]
times = [l[:5] for l in times]

words = set()
for l in sentences:
    for w in l:
        words.add(w)
for w in list(words):
    assert len(w) < 16

order = []
for l in sentences:
    words = l
    i = 0
    for word in words: ## see if we need to add word to ordred words
        if word not in order[i:]:
            order.insert(i + 1, word)
            i = i + 1
        else:
            i = order.index(word, i)
        if False:
            print word
            print ' '.join(words)
            print ', '.join(order)
            print

## define the partial ordering on the numbers
## a < b if a occurs before b in a sentence
def getAdj(order):
    n = len(order)
    adj = zeros((n, n), bool)
    for s in numeric:
        for ii, i in enumerate(s[:-1]):
            adj[s[ii], s[ii + 1]] = True
    return adj
words = set(order)

def precedence(adj, max_dist):
    ### a non zero in the i, j, entry is True if word i must preceed word j
    n = len(adj)
    adj = array(adj, copy=True).astype(int)
    A_n = eye(n).astype(int)
    out = eye(n).astype(int)
    for i in range(max_dist):
        A_n = dot(adj, A_n)
        out += A_n
    return (out  - eye(n)).astype(bool).astype(int)
# 
# A = array([[0, 1, 0, 1],[0, 0, 1, 1], [0, 0, 0, 1], [0, 0, 0, 0]])
# print A
# print precedence(A, 10)

def maximal_dist(adj, diameter):
    out = array(adj, copy=True).astype(int)
    n = len(adj)
    A_n = eye(n)
    for i in range(1, diameter):
        A_n = dot(adj, A_n).astype(bool)
        not_A_n = True - A_n
        out = out * not_A_n +  A_n * i
    return out

def mat_pow(a, k):
    out = eye(a.shape[0])
    for i in range(k):
        out = dot(out, a)
    return out

def minimal_dist(adj, diameter):
    n = len(adj)
    shape = (diameter, n, n)
    A_ns = zeros(shape, int)
    for i in range(diameter):
        A_ns[i] = mat_pow(adj, i)
    for i in range(diameter):
        A_ns[i] = where(A_ns[i], i, diameter)
    out = amin(A_ns, axis=0)
    return where(equal(out, diameter), 0, out)

V_MAT = zeros((100, 100), bool)
for i in range(100): ## 100:: can be any number larger than the number of words
    V_MAT[i,:i] = 1
def is_poset(adj):
    n = len(adj)
    A = precedence(adj, 10)
    return sum(ravel(A * V_MAT[:n, :n])) == 0

def delete_word(adj, idx):
    n = len(adj)
    out = zeros((n - 1, n - 1), adj.dtype)
    out[:idx, :idx] = adj[:idx, :idx]
    out[:idx,idx:] = adj[:idx,idx+1:]
    out[idx:,:idx] = adj[idx+1:,:idx]
    out[idx:,idx:] = adj[idx+1:,idx+1:]
    return out

def validate(order, sentences):
    for sentence in sentences:
        i = 0
        for w in sentence:
            if w in order[i:]:
                pass
            else:
                return False
            i = order.index(w, i) + 1
    return True
order_cp = order[:]
i = 0
print 'pruning redundant words'
print len(order_cp)


if False:
    rm_count = 0
    for i in range(len(order)):
        w = order[i]
        order_cp = order[:i] + order[i+1:]
        if validate(order_cp, sentences):
            print w, 'redundent'
order_cp = order[:]
i = 0
while i < len(order_cp):
    w = order_cp[i]
    order_cp = order_cp[:i] + order_cp[i+1:]
    
    ## see if later word can replace earlier word and still be valid
    if validate(order_cp, sentences):
        # print 'rm', w
        pass
    else:
        order_cp.insert(i, w)
        i += 1
print 'before pruning: n_word=%d, n_letter=%d' % (len(order), sum([len(w) for w in order]))
print ' after pruning: n_word=%d, n_letter=%d' % (len(order_cp), sum([len(w) for w in order_cp]))

porder = order_cp
# porder = open("Irish_v5_porder.txt").read().split()
print porder
assert validate(porder, sentences)

### now we have a minimal set of words that we can reference by index.  Turn the sentences in to a sequence of induces.
numeric = []

for l in sentences:
    # print ' '.join(l)
    i = 0
    ns = []
    for w in l:
        try:
            i = porder.index(w, i)
        except:
            print ' '.join(l)
            print w
            print porder.index(w), i
            print ','.join(porder)
            raise
        ns.append(i)
    numeric.append(ns)


adj = getAdj(porder)
min_dist = minimal_dist(adj, 30)
print 'Pruned list:', ' '.join(porder)


A = precedence(adj, 20)
assert is_poset(adj)

figure(3)
max_dist = maximal_dist(adj, 100)
min_dist = minimal_dist(adj, 100)
dia = max(max_dist.ravel())
print 'max_dist from origin', dia
subplot(311); pcolormesh(max_dist)
colorbar()
title('Maximal Dist')
subplot(312); pcolormesh(min_dist)
colorbar()
subplot(313); pcolormesh(A)
colorbar()

## choose first word to be the word that preceeds the most other words
first_index = argmax(sum(A, axis=1))
head = porder[first_index] ## first word

# the find maximal distance from first word to each other word


dist_from_head = max_dist[first_index]
tree = []
for i in range(13):
    tree.append([j for j in range(len(porder)) if dist_from_head[j] == i])
    
n_poss = 1
n  = len(A)
print tree
for k in range(len(tree)):
    print k, len(porder[k]), ' '.join([porder[i] for i in tree[k]])
    if k + 1 < len(tree):
        for j in tree[k + 1]:
            for i in tree[k]:
                print int(A[i, j]),
            print
        print
        print

def overlap(s1, s2):
    n = min([len(s1), len(s2)])
    out = 0
    for i in range(1, n + 1):
        if s1[-i:] == s2[:i]:
            out = i
    return out
def overlap__test__():
    assert overlap("justin", "in case") == 2
    assert overlap("justin", "boston") == 0
    assert overlap("justin", "justin") == 6
overlap__test__()

def addword(letters, word):
    '''
    add word to letter matrix.  put a space if you don't want to overlap
    '''
    x = overlap(letters, word)
    if len(word) - x <= len(letters) % 16:
        letters = letters + word[x:]
    else:
        letters += ' '  * (len(letters) % 16)
        letters += word
    return letters

def doit(sofar, tree):
    if len(tree) == 0:
        out = sofar
    else:
        tree = [l[:] for l in tree]
        word = porder[tree[0].pop(0)]
        if len(tree[0]) == 0:
            tree.pop(0)
        sofar = addword(sofar, word)
        return doit(sofar, tree)
    return out

figure(1)
A_n = eye(len(porder))
for i in range(dia):
    subplot(5, 3, i + 1)
    A_n = dot(A_n, adj)
    pcolormesh(A_n)

figure(2)
ax = subplot(211)
title("Irish_v3 precedence")
pcolormesh(adj)
subplot(212, sharex=ax, sharey=ax)
pcolormesh(A)
# show()
for w in porder:
    print w
