#!/usr/bin/python

# Accumulatore originale di accumunet
acc = int("450da364ae10b42c83f180d01fecf5cbd0901d4b1b8eed22d8490d46a42a65e7", 16)
print(format(acc, 'x').upper())
# Witness
wit1 = int("357d626250e41eb0390d60e4c33859369681fec371ab532e428b63059e97c6a7", 16)
wit2 = int("26ff76d0f66b8403bda6534fce3dbcaf47ffd5eb7e06720dd3d58aee587a39a5", 16)
wit3 = int("450da364ae10b42c83f180d01fecf5cbd0901d4b1b8eed22d8490d46a42a65e7", 16)
# Numero primo corrispondente a utente1
prime1 = int("C0BE5762F01227B3AE7C0A456DBAC88041124C8404DDFE1B36B11746F418F5AB", 16)
prime2 = int("F1F93345271CEFA71250BFC6AF271E24B5FF75ECD9D14093BCCEA45F36FDE90F", 16)
prime3 = int("DEDE890621DA2BA78870D313DA376B5F57571E70C162570283D8510CD42D20FB", 16)
# Il modulo dell'esponenziazione
mod = int("625db8b14abe99dd61d65eb05742e10916148354c764b58d6f0e84dda9fa9b77", 16)

# Verifica dell'accumulatore
res = pow(wit1, prime1, mod)
print("Utente 1: " + str(res==acc))

res = pow(wit2, prime2, mod)
print("Utente 2: " + str(res==acc))

res = pow(wit3, prime3, mod)
print("Utente 3: " + str(res==acc))

newacc = pow(acc, prime3, mod)
print(format(newacc, 'x').upper())
# newacc = 3588218553743141645655309492248443571709045705968912482778341095062769902789
newwit3 = acc

res = pow(newwit3, prime3, mod)
print("Utente 3: " + str(res==newacc))