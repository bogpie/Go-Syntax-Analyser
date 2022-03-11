build:
	flex tema.l
	gcc lex.yy.c -o exec

run:
	./exec input1

clean:
	rm lex.yy.c
	rm exec
