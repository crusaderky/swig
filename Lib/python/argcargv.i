/* -------------------------------------------------------------
 * SWIG library containing argc and argv multi-argument typemaps
 * ------------------------------------------------------------- */

%fragment("SWIG_AsArgcArgv", "header", fragment="SWIG_AsCharPtrAndSize") {
SWIGINTERN int
SWIG_AsArgcArgv(PyObject *input, swig_type_info *ppchar_info, size_t *argc, char ***argv, int *owner) {
  void *vptr;
  int res = SWIG_ConvertPtr(input, &vptr, ppchar_info, 0);
  if (!SWIG_IsOK(res)) {
    res = SWIG_OK;
    PyErr_Clear();
    int is_list = PyList_Check(input);
    if (!is_list && !PyTuple_Check(input)) return SWIG_TypeError;

    Py_BEGIN_CRITICAL_SECTION(input);
    size_t i = 0;
    size_t size = is_list ? PyList_Size(input) : PyTuple_Size(input);
    if (argc) *argc = size;
    if (argv) {
      *argv = %new_array(size + 1, char*);
      for (; i < size; ++i) {
        PyObject *obj = is_list ? PyList_GetItem(input, i) : PyTuple_GetItem(input, i);
        char *cptr = 0; size_t sz = 0; int alloc = 0;
        res = SWIG_AsCharPtrAndSize(obj, &cptr, &sz, &alloc);
        if (!SWIG_IsOK(res)) break;
        if (cptr && sz) {
          (*argv)[i] = (alloc == SWIG_NEWOBJ) ? cptr : %new_copy_array(cptr, sz, char);
        } else {
          (*argv)[i] = 0;
        }
      }
      (*argv)[i] = 0;
      if (owner) *owner = 1;
    } else {
      for (; i < size; ++i) {
        PyObject *obj = is_list ? PyList_GetItem(input, i) : PyTuple_GetItem(input, i);
        res = SWIG_AsCharPtrAndSize(obj, 0, 0, 0);
        if (!SWIG_IsOK(res)) break;
      }
      if (owner) *owner = 0;
    }
    Py_END_CRITICAL_SECTION();
    return res;

  } else {
    /* seems dangerous, but the user asked for it... */
    size_t i = 0;
    if (argv && *argv) { while ((*argv)[i] != 0) ++i; }
    if (argc) *argc = i;
    if (owner) *owner = 0;
    return SWIG_OK;
  }
}
}

/*
  This typemap works with either a char **, a python list or a python
  tuple
 */

%typemap(in,noblock=0,fragment="SWIG_AsArgcArgv") (int ARGC, char **ARGV) (int res,char **argv = 0, size_t argc = 0, int owner= 0) {
  res = SWIG_AsArgcArgv($input, $descriptor(char**), &argc, &argv, &owner);
  if (!SWIG_IsOK(res)) {
    $1 = 0; $2 = 0;
    %argument_fail(SWIG_TypeError, "int ARGC, char **ARGV", $symname, $argnum);
  } else {
    $1 = %static_cast(argc,$1_ltype);
    $2 = %static_cast(argv, $2_ltype);
  }
}

%typemap(typecheck, precedence=SWIG_TYPECHECK_STRING_ARRAY) (int ARGC, char **ARGV) {
  int res = SWIG_AsArgcArgv($input, $descriptor(char**), 0, 0, 0);
  $1 = SWIG_IsOK(res);
}

%typemap(freearg,noblock=1) (int ARGC, char **ARGV)  {
  if (owner$argnum) {
    size_t i = argc$argnum;
    while (i) {
      %delete_array(argv$argnum[--i]);
    }
    %delete_array(argv$argnum);
  }
}

