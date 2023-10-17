quants = input().split(" ")
torres = input().split(" ")

posicaoAntiga = int(torres[0])
danos = []
for i in range(1, len(torres)):
    danos.append(posicaoAntiga - int(torres[i]))
    posicaoAntiga = int(torres[i])

limit = int(quants[0])
tmp = [0 for i in range(limit)]
aux = [0 for i in range(limit)]

for j in range(1, len(torres)):
    if (danos[j - 1] > 0):
        tmp[j] = danos[j - 1] + tmp[j - 1]
    else:
        tmp[j] = tmp[j - 1]

for j in range(len(danos) - 1, -1, -1):
    if (danos[j] < 0):
        aux[j] = danos[j] * -1 + aux[j + 1]
    else:
        aux[j] = aux[j + 1]

for i in range(int(quants[1])):
    missao = input().split(" ")
    inicio = int(missao[0]) - 1
    fim = int(missao[1]) - 1

    if (inicio < fim):
        print(tmp[fim] - tmp[inicio])
    else:
        print(aux[fim] - aux[inicio])