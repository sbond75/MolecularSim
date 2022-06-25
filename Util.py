# import pdb
# pdb.set_trace()

# NOTE: You must pass `globals=globals(), locals=locals()` manually for this to work properly.
def startREPL(globals=globals(), locals=locals()):
    from ptpython.repl import embed
    embed(globals, locals)
