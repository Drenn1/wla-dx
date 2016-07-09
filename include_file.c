
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "defines.h"

#include "include_file.h"
#include "pass_1.h"
#include "parse.h"


extern int ind, inz, i, unfolded_size, extra_definitions, d, use_incdir;
extern char *unfolded_buffer, emsg[256], tmp[4096];
extern FILE *file_out_ptr;

extern int include_paths_count;
extern char **include_paths;

struct incbin_file_data *incbin_file_data_first = NULL, *ifd_tmp;
struct active_file_info *active_file_info_first = NULL, *active_file_info_last = NULL, *active_file_info_tmp;
struct file_name_info *file_name_info_first = NULL, *file_name_info_last = NULL, *file_name_info_tmp;
char *include_in_tmp = NULL, *tmp_a = NULL;
int include_in_tmp_size = 0, tmp_a_size = 0, file_name_id = 1, open_files = 0;

char *full_name = NULL;
int full_name_size = 0;

char *include_dir = NULL;
int include_dir_size = 0;

char *buffer = NULL;
struct token_stack_root *buffer_stack = NULL;
int size = 0;


int create_full_name(char *dir, char *name) {

  char *tmp;
  int i;

  
  if (dir == NULL && name == NULL)
    return SUCCEEDED;

  /* compute the length of the new string */
  i = 0;
  if (dir != NULL)
    i += strlen(dir);
  if (name != NULL)
    i += strlen(name);
  i++;

  if (i > full_name_size) {
    tmp = realloc(full_name, i);
    if (tmp == NULL) {
      fprintf(stderr, "CREATE_FULL_NAME: Out of memory error.\n");
      return FAILED;
    }
    full_name = tmp;
    full_name_size = i;
  }

  if (dir != NULL) {
    strcpy(full_name, dir);
    if (name != NULL)
      strcat(full_name, name);
  }
  else
    strcpy(full_name, name);

  return SUCCEEDED;
}

FILE *get_include_file(char *name, char **include_name) {
  FILE *file = NULL;
  int file_index;

  /* Scan for files using the following folder priority. */
  /* 1. Command line include directories. */
  /* 2. Source file INCDIR paths. */
  /* 3. Relative to the source file. */

  /* 1. Command line include directories. */
  if (use_incdir == YES) {
    for (file_index = 0; file_index < include_paths_count; ++file_index) {
      if (create_full_name(include_paths[file_index], name) != FAILED) {
        file = fopen(full_name, "rb");

        if (file != NULL) {
          *include_name = full_name;
          break;
        }
      }
    }
  }

  /* 2. Source file INCDIR path. */
  if (file == NULL && include_dir != NULL && include_dir[0] != 0) {
    if (create_full_name(include_dir, name) != FAILED) {
      file = fopen(full_name, "rb");

      if (file != NULL)
        *include_name = full_name;
    }
  }

  /* 3. Relative to the source file. */
  if (file == NULL) {
    file = fopen(name, "rb");

    if (file != NULL)
      *include_name = name;
  }

  return file;
}


int include_file(char *name) {

  static int first_load = 0;
  int file_size, id;
  char *tmp_b, *n, *tmp_c;
  FILE *f;

  f = get_include_file (name, &tmp_c);

  if (f != NULL) {
    /* Generate and store the full_name if a valid file was found. */
    create_full_name(NULL, tmp_c);
  }
  else {
    sprintf(emsg, "Error opening file \"%s\".\n", name);
    fprintf(stderr, "INCLUDE_FILE: %s", emsg);

    return FAILED;
  }

  first_load = 1;

  if (extra_definitions == ON) {
    redefine("WLA_FILENAME", 0.0, name, DEFINITION_TYPE_STRING, strlen(name));
    redefine("wla_filename", 0.0, name, DEFINITION_TYPE_STRING, strlen(name));
  }

  fseek(f, 0, SEEK_END);
  file_size = ftell(f);
  fseek(f, 0, SEEK_SET);

  active_file_info_tmp = malloc(sizeof(struct active_file_info));
  if (active_file_info_tmp == NULL) {
    sprintf(emsg, "Out of memory while trying allocate error tracking data structure for file \"%s\".\n", full_name);
    print_error(emsg, ERROR_INC);
    return FAILED;
  }
  active_file_info_tmp->next = NULL;

  if (active_file_info_first == NULL) {
    active_file_info_first = active_file_info_tmp;
    active_file_info_last = active_file_info_tmp;
    active_file_info_tmp->prev = NULL;
  }
  else {
    active_file_info_tmp->prev = active_file_info_last;
    active_file_info_last->next = active_file_info_tmp;
    active_file_info_last = active_file_info_tmp;
  }

  active_file_info_tmp->line_current = 1;

  /* name */
  file_name_info_tmp = file_name_info_first;
  id = 0;
  while (file_name_info_tmp != NULL) {
    if (strcmp(file_name_info_tmp->name, full_name) == 0) {
      id = file_name_info_tmp->id;
      active_file_info_tmp->filename_id = id;
      break;
    }
    file_name_info_tmp = file_name_info_tmp->next;
  }

  if (id == 0) {
    file_name_info_tmp = malloc(sizeof(struct file_name_info));
    n = malloc(strlen(full_name)+1);
    if (file_name_info_tmp == NULL || n == NULL) {
      if (file_name_info_tmp != NULL)
	free(file_name_info_tmp);
      if (n != NULL)
	free(n);
      sprintf(emsg, "Out of memory while trying allocate info structure for file \"%s\".\n", full_name);
      print_error(emsg, ERROR_INC);
      return FAILED;
    }
    file_name_info_tmp->next = NULL;

    if (file_name_info_first == NULL) {
      file_name_info_first = file_name_info_tmp;
      file_name_info_last = file_name_info_tmp;
    }
    else {
      file_name_info_last->next = file_name_info_tmp;
      file_name_info_last = file_name_info_tmp;
    }

    strcpy(n, full_name);
    file_name_info_tmp->name = n;
    active_file_info_tmp->filename_id = file_name_id;
    file_name_info_tmp->id = file_name_id;
    file_name_id++;
  }

  /* reallocate buffer */
  if (include_in_tmp_size < file_size) {
    if (include_in_tmp != NULL)
      free(include_in_tmp);

    include_in_tmp = malloc(sizeof(char) * file_size);
    if (include_in_tmp == NULL) {
      sprintf(emsg, "Out of memory while trying to allocate room for \"%s\".\n", full_name);
      print_error(emsg, ERROR_INC);
      return FAILED;
    }

    include_in_tmp_size = file_size;
  }

  /* read the whole file into a buffer */
  fread(include_in_tmp, 1, file_size, f);
  fclose(f);

  if (size == 0) {
    buffer = malloc(sizeof(char) * (file_size + 4));
    if (buffer == NULL) {
      sprintf(emsg, "Out of memory while trying to allocate room for \"%s\".\n", full_name);
      print_error(emsg, ERROR_INC);
      return FAILED;
    }

    /* preprocess */
    preprocess_file(include_in_tmp, include_in_tmp + file_size, buffer, &size, full_name);

    buffer[size++] = 0xA;
    buffer[size++] = '.';
    buffer[size++] = 'E';
    buffer[size++] = ' ';

    open_files++;

    if (buffer_stack == NULL) {
      /* Allocate the initial buffer stack. */
      buffer_stack = token_stack_new(buffer, 0);
    }
    else {
      /* Update the buffer entry. */
      buffer_stack->active_entry->buffer_root = buffer;
    }

    return SUCCEEDED;
  }

  tmp_b = malloc(sizeof(char) * (size + file_size + 4));
  if (tmp_b == NULL) {
    sprintf(emsg, "Out of memory while trying to expand the project to incorporate file \"%s\".\n", full_name);
    print_error(emsg, ERROR_INC);
    return FAILED;
  }

  /* reallocate tmp_a */
  if (tmp_a_size < file_size + 4) {
    if (tmp_a != NULL)
      free(tmp_a);

    tmp_a = malloc(sizeof(char) * (file_size + 4));
    if (tmp_a == NULL) {
      sprintf(emsg, "Out of memory while allocating new room for \"%s\".\n", full_name);
      print_error(emsg, ERROR_INC);
      return FAILED;
    }

    tmp_a_size = file_size + 4;
  }

  /* preprocess */
  inz = 0;
  preprocess_file(include_in_tmp, include_in_tmp + file_size, tmp_a, &inz, full_name);

  tmp_a[inz++] = 0xA;
  tmp_a[inz++] = '.';
  tmp_a[inz++] = 'E';
  tmp_a[inz++] = ' ';

  open_files++;

  {
    struct token_stack_entry *entry = buffer_stack->active_entry;

    while (entry->parent_entry != NULL)
      entry = entry->parent_entry;

    i = entry->buffer_offset;
  }

  /* Splice the new file in the buffer. */
  memcpy(tmp_b, buffer, i);
  memcpy(tmp_b + i, tmp_a, inz);
  memcpy(tmp_b + i + inz, buffer + i, size - i);

  free(buffer);

  size += inz;
  buffer = tmp_b;

  if (buffer_stack == NULL) {
    /* Allocate the initial buffer stack. */
    buffer_stack = token_stack_new(buffer, 0);
  }
  else {
    /* Update the buffer entry. */
    buffer_stack->active_entry->buffer_root = buffer;
  }

  return SUCCEEDED;
}


int incbin_file(char *name, int *id, int *swap, int *skip, int *read, struct macro_static **macro) {

  struct incbin_file_data *ifd;
  char *in_tmp, *n, *tmp_c;
  int file_size, q;
  FILE *f;

  f = get_include_file(name, &tmp_c);

  if (f != NULL) {
    /* Generate and store the full_name if a valid file was found. */
    create_full_name(NULL, tmp_c);
  }
  else {
    sprintf(emsg, "Error opening file \"%s\".\n", name);
    fprintf(stderr, "INCLUDE_FILE: %s", emsg);

    return FAILED;
  }

  fseek(f, 0, SEEK_END);
  file_size = ftell(f);
  fseek(f, 0, SEEK_SET);

  ifd = (struct incbin_file_data *)malloc(sizeof(struct incbin_file_data));
  n = malloc(sizeof(char) * (strlen(full_name)+1));
  in_tmp = (char *)malloc(sizeof(char) * file_size);
  if (ifd == NULL || n == NULL || in_tmp == NULL) {
    if (ifd != NULL)
      free(ifd);
    if (n != NULL)
      free(n);
    if (in_tmp != NULL)
      free(in_tmp);
    sprintf(emsg, "Out of memory while allocating data structure for \"%s\".\n", full_name);
    print_error(emsg, ERROR_INB);
    return FAILED;
  }

  /* read the whole file into a buffer */
  fread(in_tmp, 1, file_size, f);
  fclose(f);

  /* complete the structure */
  ifd->next = NULL;
  ifd->size = file_size;
  strcpy(n, full_name);
  ifd->name = n;
  ifd->data = in_tmp;

  /* find the index */
  q = 0;
  if (incbin_file_data_first != NULL) {
    ifd_tmp = incbin_file_data_first;
    while (ifd_tmp->next != NULL && strcmp(ifd_tmp->name, full_name) != 0) {
      ifd_tmp = ifd_tmp->next;
      q++;
    }
    if (ifd_tmp->next == NULL && strcmp(ifd_tmp->name, full_name) != 0) {
      ifd_tmp->next = ifd;
      q++;
    }
  }
  else
    incbin_file_data_first = ifd;

  *id = q;

  /* SKIP bytes? */
  if (compare_next_token("SKIP", 4) == FAILED)
    *skip = 0;
  else {
    skip_next_token();
    inz = input_number();
    if (inz != SUCCEEDED) {
      print_error(".INCBIN needs the amount of skipped bytes.\n", ERROR_DIR);
      return FAILED;
    }

    *skip = d;

    if (d >= file_size) {
      sprintf(emsg, "SKIP value (%d) is more than the size (%d) of file \"%s\".\n", d, file_size, full_name);
      print_error(emsg, ERROR_INB);
      return FAILED;
    }
  }

  /* READ bytes? */
  if (compare_next_token("READ", 4) == FAILED)
    *read = file_size - *skip;
  else {
    skip_next_token();
    inz = input_number();
    if (inz != SUCCEEDED) {
      print_error(".INCBIN needs the amount of bytes for reading.\n", ERROR_DIR);
      return FAILED;
    }

    *read = d;

    if (*skip + *read > file_size) {
      sprintf(emsg, "Overreading file \"%s\" by %d bytes.\n", full_name, *skip + *read - file_size);
      print_error(emsg, ERROR_INB);
      return FAILED;
    }
  }

  /* SWAP bytes? */
  if (compare_next_token("SWAP", 4) == FAILED)
    *swap = 0;
  else {
    if ((*read & 1) == 1) {
      sprintf(emsg, "The read size of file \"%s\" is odd (%d)! Cannot perform SWAP.\n", full_name, *read);
      print_error(emsg, ERROR_INB);
      return FAILED;
    }
    *swap = 1;
    skip_next_token();
  }

  /* FSIZE? */
  if (compare_next_token("FSIZE", 5) == SUCCEEDED) {
    skip_next_token();

    /* get the definition label */
    if (get_next_token() == FAILED)
      return FAILED;

    add_a_new_definition(tmp, (double)file_size, NULL, DEFINITION_TYPE_VALUE, 0);
  }

  /* FILTER? */
  if (compare_next_token("FILTER", 6) == SUCCEEDED) {
    skip_next_token();

    /* get the filter macro name */
    if (get_next_token() == FAILED)
      return FAILED;

    *macro = macro_get(tmp);

    if (*macro == NULL) {
      sprintf(emsg, "No MACRO \"%s\" defined.\n", tmp);
      print_error(emsg, ERROR_INB);
      return FAILED;
    }
  }
  else
    *macro = NULL;

  return SUCCEEDED;
}


char get_file_name_error[] = "GET_FILE_NAME: Internal error.";


char *get_file_name(int id) {

  struct file_name_info *fni;

  
  fni = file_name_info_first;
  while (fni != NULL) {
    if (id == fni->id)
      return fni->name;
    fni = fni->next;
  }

  return get_file_name_error;
}


int print_file_names(void) {

  struct incbin_file_data *ifd;
  struct file_name_info *fni;

  
  fni = file_name_info_first;
  ifd = incbin_file_data_first;

  /* handle the main file name differently */
  if (fni != NULL) {
    if (fni->next != NULL || ifd != NULL)
      fprintf(stdout, "%s \\\n", fni->name);
    else
      fprintf(stdout, "%s\n", fni->name);
    fni = fni->next;
  }

  /* included files */
  while (fni != NULL) {
    if (fni->next != NULL || ifd != NULL)
      fprintf(stdout, "\t%s \\\n", fni->name);
    else
      fprintf(stdout, "\t%s\n", fni->name);
    fni = fni->next;
  }

  /* incbin files */
  while (ifd != NULL) {
    if (ifd->next != NULL)
      fprintf(stdout, "\t%s \\\n", ifd->name);
    else
      fprintf(stdout, "\t%s\n", ifd->name);
    ifd = ifd->next;
  }

  return SUCCEEDED;
}


/* the mystery preprocessor - touch it and prepare for trouble ;) the preprocessor
   removes as much white space as possible from the source file. this is to make
   the parsing of the file, that follows, simpler. */
int preprocess_file(char *input, char *input_end, char *out_buffer, int *out_size, char *file_name) {

  /* this is set to 1 when the parser finds a non white space symbol on the line it's parsing */
  register int got_chars_on_line = 0;

  char *output = out_buffer;

  while (input < input_end) {
    switch (*input) {
    case ';':
      /* clear a commented line */
      input++;
      for ( ; input < input_end && *input != 0x0A && *input != 0x0D; input++)
	;
      output--;
      for ( ; output > out_buffer && *output == ' '; output--)
	;
      if (output < out_buffer)
	output = out_buffer;
      else if (*output != ' ')
	output++;
      break;
    case '*':
      if (got_chars_on_line == 0) {
	/* clear a commented line */
	input++;
	for ( ; input < input_end && *input != 0x0A && *input != 0x0D; input++)
	  ;
      }
      else {
	/* multiplication! */
	input++;
	*output = '*';
	output++;
      }
      break;
    case '/':
      if (*(input + 1) == '*') {
	/* remove an ANSI C -style block comment */
	got_chars_on_line = 0;
	input += 2;
	while (got_chars_on_line == 0) {
	  for ( ; input < input_end && *input != '/' && *input != 0x0A; input++)
	    ;
	  if (input >= input_end) {
	    sprintf(emsg, "Comment wasn't terminated properly in file \"%s\".\n", file_name);
	    print_error(emsg, ERROR_INC);
	    return FAILED;
	  }
	  if (*input == 0x0A) {
	    *output = 0x0A;
	    output++;
	  }
	  if (*input == '/' && *(input - 1) == '*') {
	    got_chars_on_line = 1;
	  }
	  input++;
	}
	output--;
	for ( ; output > out_buffer && *output == ' '; output--)
	  ;
	if (output < out_buffer)
	  output = out_buffer;
	else if (*output != ' ')
	  output++;
      }
      else {
	input++;
	*output = '/';
	output++;
	got_chars_on_line = 1;
      }
      break;
    case ':':
      /* finding a label resets the counters */
      input++;
      *output = ':';
      output++;
      got_chars_on_line = 0;
      break;
    case 0x09:
    case ' ':
      /* remove extra white space */
      input++;
      *output = ' ';
      output++;
      for ( ; input < input_end && (*input == ' ' || *input == 0x09); input++)
	;
      got_chars_on_line = 1;
      break;
    case 0x0A:
      /* take away white space from the end of the line */
      input++;
      output--;
      for ( ; *output == ' '; output--)
	;
      output++;
      *output = 0x0A;
      output++;
      /* moving on to a new line */
      got_chars_on_line = 0;
      break;
    case 0x0D:
      input++;
      break;
    case '\'':
      if (*(input + 2) == '\'') {
	*output = '\'';
	input++;
	output++;
	*output = *input;
	input++;
	output++;
	*output = '\'';
	input++;
	output++;
      }
      else {
	*output = '\'';
	input++;
	output++;
      }
      got_chars_on_line = 1;
      break;
    case '"':
      /* don't touch strings */
      *output = '"';
      input++;
      output++;
      got_chars_on_line = 1;
      while (1) {
	for ( ; input < input_end && *input != '"' && *input != 0x0A && *input != 0x0D; ) {
	  *output = *input;
	  input++;
	  output++;
	}

	if (input >= input_end)
	  break;
	else if (*input == 0x0A || *input == 0x0D) {
	  /* process 0x0A/0x0D as usual, and later when we try to input a string, the parser will fail as 0x0A comes before a " */
	  break;
	}
	else if (*input == '"' && *(input - 1) != '\\') {
	  *output = '"';
	  input++;
	  output++;
	  break;
	}
	else {
	  *output = '"';
	  input++;
	  output++;
	}
      }
      break;
#if !defined(W65816) && !defined(SPC700)
    case '[':
      /* change '[' to '(' */
#endif
    case '(':
      *output = '(';
      input++;
      output++;
      for ( ; input < input_end && (*input == ' ' || *input == 0x09); input++)
	;
      got_chars_on_line = 1;
      break;
#if !defined(W65816) && !defined(SPC700)
    case ']':
      /* change ']' to ')' */
#endif
    case ')':
      /* go back? */
      if (got_chars_on_line == 1 && *(output - 1) == ' ')
	output--;
      *output = ')';
      input++;
      output++;
      got_chars_on_line = 1;
      break;
#if defined(W65816) || defined(SPC700)
    case '[':
      *output = *input;
      input++;
      output++;
      got_chars_on_line = 1;
      break;
#endif
    case ',':
    case '+':
    case '-':
      if (got_chars_on_line == 0) {
	for ( ; input < input_end && (*input == '+' || *input == '-'); input++, output++)
	  *output = *input;
	got_chars_on_line = 1;
      }
      else {
	*output = *input;
	input++;
	output++;
	for ( ; input < input_end && (*input == ' ' || *input == 0x09); input++)
	  ;
	got_chars_on_line = 1;
      }
      break;
    default:
      *output = *input;
      input++;
      output++;
      got_chars_on_line = 1;

      break;
    }
  }

  *out_size = output - out_buffer;

  return SUCCEEDED;
}
