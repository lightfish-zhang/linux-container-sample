CC=gcc
LIBOBJS:=
OBJS:=main.o
OUT:=linux-container.out

all: $(OUT) 

$(OUT): $(OBJS) $(LIBOBJS)
	$(CC) -o $@ $^ 

clean:
	rm -f $(OBJS); rm -f $(OUT); rm -f $(LIBOBJS);
