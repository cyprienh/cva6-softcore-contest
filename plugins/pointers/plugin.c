#include <gcc-plugin.h>                 
#include <plugin-version.h>
#include <rtl.h>
#include <target.h>          
#include <tree.h>
#include <tree-pass.h>
#include <stringpool.h>
#include <attribs.h>
#include <memmodel.h>
#include <emit-rtl.h>

#include <print-tree.h>
#include <print-rtl.h>
#include <tree-iterator.h>
#include <c-family/c-common.h>
#include <c-tree.h>

#include "gimple.h"
#include "gimple-iterator.h"
#include "gimple-walk.h"
#include "gimple-pretty-print.h"
#include <cgraph.h>
#include <asan.h>
#include <tree-ssa-operands.h>

#define FN_NAME(t) IDENTIFIER_POINTER(DECL_NAME(t))

int plugin_is_GPL_compatible; // must be defined & exported for the plugin to be loaded

extern gcc::context *g;

static void gimple_process_function_body(tree expr) {
  if (! expr) return;
  fprintf(stderr, "tree_code: %s\n", get_tree_code_name(TREE_CODE(expr)));
  if (TREE_CODE(expr) == BIND_EXPR) {
    for (tree var = BIND_EXPR_VARS(expr); var; var = DECL_CHAIN(var)) {
      gcc_assert(TREE_CODE(var) == VAR_DECL);
      tree id = DECL_NAME(var);
      tree type = TREE_TYPE(var);
      if (TREE_CODE(type) == POINTER_TYPE) {
        tree ptr_type = TREE_TYPE(type);
        if (TREE_CODE(ptr_type) == FUNCTION_TYPE) {
          fprintf(stderr, "=> pointer detected\n");
        }
      }
    }
    tree body = BIND_EXPR_BODY(expr);
    gimple_process_function_body(body);
  } else if (TREE_CODE(expr) == STATEMENT_LIST) {
    for (tree_stmt_iterator i = tsi_start(expr); !tsi_end_p(i); tsi_next(&i)) {
      tree stmt = tsi_stmt(i);
      gimple_process_function_body(stmt);
    }
  } else if (TREE_CODE(expr) == CALL_EXPR) {
    //debug_tree(expr);
  } else if (TREE_CODE(expr) == MODIFY_EXPR) {
    //debug_tree(expr);
  } else if (TREE_CODE(expr) == DECL_EXPR) {
    //debug_tree(expr);
  } else if (TREE_CODE(expr) == RETURN_EXPR) {
    //debug_tree(expr);
  } else if (TREE_CODE(expr) == COND_EXPR) {
    gimple_process_function_body(COND_EXPR_COND(expr));
    gimple_process_function_body(COND_EXPR_THEN(expr));
    gimple_process_function_body(COND_EXPR_ELSE(expr));
  } else if (TREE_CODE(expr) == PARM_DECL) {
    //debug_tree(expr);
  } else {
    fprintf(stderr, "!!! NOT HANDLED YET (gimple_process_function_body) !!!\n");
    debug_tree(expr);
  }
}

// ###################

// On peut renforcer un pointeur, uniquement si il n'est pas passé en argument
// à d'autres fonctions, par adresse.

int gimple_can_harden_pointer_aux_tree(tree var, tree stmt) {
  if (! stmt) {
    return 1;
  } else if (TREE_CODE(stmt) == CONSTRUCTOR) {
    return 1;
  } else if (TREE_CODE(stmt) == VAR_DECL) {
    return 1;
  } else if (TREE_CODE(stmt) == INTEGER_CST) {
    return 1;
  } else if (TREE_CODE(stmt) == ADDR_EXPR) { // See gcc/gimple-walk.cc line 801
    //tree addr = TREE_OPERAND(stmt, 0);
    //debug_tree(addr);
    return 1;
  } else if (TREE_CODE(stmt) == PARM_DECL) {
    // TODO: regarder le nom et l'indice.
    return 1;
  } else if (TREE_CODE(stmt) == SSA_NAME) {
    return 1;
  }
  fprintf(stderr, "!!! NOT HANDLED YET (gimple_can_harden_pointer_aux_tree) !!!\n");
  debug_tree(stmt);
  return 0;
}

int gimple_can_harden_pointer_aux(tree var, gimple* stmt) {
  enum gimple_code code = gimple_code(stmt);
  fprintf(stderr, "statement of type: %s\n", gimple_code_name[code]);
  debug_gimple_stmt(stmt);
  // See pp_gimple_stmt_1 (gimple-pretty-print.cc)
  if (code == GIMPLE_ASSIGN) { //is_gimple_assign(stmt)
    if (! gimple_can_harden_pointer_aux_tree(var, gimple_assign_rhs3(stmt))) return 0;
    if (! gimple_can_harden_pointer_aux_tree(var, gimple_assign_rhs2(stmt))) return 0;
    if (! gimple_can_harden_pointer_aux_tree(var, gimple_assign_rhs1(stmt))) return 0;
    return 1;
  } else if (code == GIMPLE_CALL) {
    for (int i = 0; i < gimple_call_num_args(stmt); i++) {
      if (! gimple_can_harden_pointer_aux_tree(var, gimple_call_arg(stmt, i))) return 0;
    } 
    return 1;
  } else if (code == GIMPLE_RETURN) {
    if (! gimple_can_harden_pointer_aux_tree(var, gimple_return_retval(as_a <const greturn *> (stmt)))) return 0;
    return 1;
  } else if (code == GIMPLE_COND) {
    if (! gimple_can_harden_pointer_aux_tree(var, gimple_cond_lhs(as_a <const gcond *> (stmt)))) return 0;
    if (! gimple_can_harden_pointer_aux_tree(var, gimple_cond_true_label(as_a <const gcond *> (stmt)))) return 0;
    if (! gimple_can_harden_pointer_aux_tree(var, gimple_cond_false_label(as_a <const gcond *> (stmt)))) return 0;
    return 1;
  } else {
    fprintf(stderr, "!!! NOT HANDLED YET (gimple_can_harden_pointer_aux) !!!\n");
    return 0;
  }
  return 0;
}

int gimple_can_harden_pointer(tree var) {
  gimple_stmt_iterator gsi;
  gimple *stmt;
  basic_block bb;
  FOR_EACH_BB_FN(bb, cfun) {
    for (gsi = gsi_start_bb(bb); !gsi_end_p(gsi); gsi_next(&gsi)) {
      stmt = gsi_stmt(gsi);
      int ret = gimple_can_harden_pointer_aux(var, stmt);
      if (! ret) return 0;
    }
  }
  return 1;
}

void gimple_harden_pointer_assign(tree ptr, tree guard) {
  gimple_stmt_iterator gsi;
  gimple *stmt;
  basic_block bb;
  FOR_EACH_BB_FN(bb, cfun) {
    for (gsi = gsi_start_bb(bb); !gsi_end_p(gsi); gsi_next(&gsi)) {
      stmt = gsi_stmt(gsi);
      enum gimple_code code = gimple_code(stmt);
      if (code == GIMPLE_ASSIGN && gimple_assign_lhs(stmt) == ptr) {
        gimple* new_stmt = gimple_build_assign(guard, ptr);
        gsi_insert_after(&gsi, new_stmt, GSI_NEW_STMT);
        //debug_tree(gimple_assign_lhs(stmt));
      }
    }
  }
}

int gimple_harden_pointer_call_aux_tree(tree var, tree stmt) {
  if (! stmt) {
    return 0;
  } else if (TREE_CODE(stmt) == CONSTRUCTOR) {
    return 0;
  } else if (TREE_CODE(stmt) == VAR_DECL) {
    return 0;
  } else if (TREE_CODE(stmt) == INTEGER_CST) {
    return 0;
  } else if (TREE_CODE(stmt) == ADDR_EXPR) { // See gcc/gimple-walk.cc line 801
    return 0;
  } else if (TREE_CODE(stmt) == PARM_DECL) {
    // TODO: regarder le nom et l'indice
    return 0;
  } else if (TREE_CODE(stmt) == SSA_NAME) {
    return SSA_NAME_IDENTIFIER(stmt) == var;
  }
  fprintf(stderr, "!!! NOT HANDLED YET (gimple_harden_pointer_call_aux_tree) !!!\n");
  debug_tree(stmt);
  return 0;
}

int gimple_harden_pointer_call_aux(tree var, gimple* stmt) {
  enum gimple_code code = gimple_code(stmt);
  fprintf(stderr, "statement of type: %s\n", gimple_code_name[code]);
  debug_gimple_stmt(stmt);
  // See pp_gimple_stmt_1 (gimple-pretty-print.cc)
  if (code == GIMPLE_ASSIGN) { //is_gimple_assign(stmt)
    if (gimple_harden_pointer_call_aux_tree(var, gimple_assign_rhs3(stmt))) return 1;
    if (gimple_harden_pointer_call_aux_tree(var, gimple_assign_rhs2(stmt))) return 1;
    if (gimple_harden_pointer_call_aux_tree(var, gimple_assign_rhs1(stmt))) return 1;
    return 0;
  } else if (code == GIMPLE_CALL) {
    tree call = gimple_call_fn(stmt);
    debug_tree(call);
    if (TREE_CODE(call) == VAR_DECL) {
      if (call == var) return 1;
    } else {
      fprintf(stderr, "XXXXXXXX\n\n\n");
      debug_tree(gimple_call_fn(stmt));
    }
    for (int i = 0; i < gimple_call_num_args(stmt); i++) {
      if (gimple_harden_pointer_call_aux_tree(var, gimple_call_arg(stmt, i))) return 1;
    } 
    return 0;
  } else if (code == GIMPLE_RETURN) {
    if (gimple_harden_pointer_call_aux_tree(var, gimple_return_retval(as_a <const greturn *> (stmt)))) return 1;
    return 0;
  } else {
    // Default... if we don't know... we suppose 'true'.
    return 1;
  }
  return 1;
}

basic_block bb_done[1024];
int bb_done_idx;
basic_block bb_todo[1024];
int bb_todo_idx;

#define IS_BB_TODO(bb, ret) \
  do { \
    ret = 1; \
    for (int _i = 0; _i < bb_done_idx; _i++) { \
      if (bb_done[_i] == bb) { \
        ret = 0; \
        break; \
      } \
    } \
    if (ret == 1) { \
      for (int _i = 0; _i < bb_todo_idx; _i++) { \
        if (bb_todo[_i] == bb) { \
          ret = 0; \
          break; \
        } \
      } \
    } \
  } while (0)

#define PUSH_BB_TODO(bb) \
  do { \
    bb_todo[bb_todo_idx] = bb; \
    bb_todo_idx++; \
  } while (0)

#define PUSH_BB_DONE(bb) \
  do { \
    bb_done[bb_done_idx] = bb; \
    bb_done_idx++; \
  } while (0)

#define POP_BB_TODO(bb) \
  do { \
    bb_todo_idx--; \
    bb = bb_todo[bb_todo_idx]; \
  } while (0)


void debug_print_graph(void) {
  basic_block bb_done[1024];
  int bb_done_idx;
  basic_block bb_todo[1024];
  int bb_todo_idx;

  edge e;
  edge_iterator ei;
  basic_block bb;
  int is_bb_todo;
  gimple_stmt_iterator gsi;

  bb_done_idx = 0;
  bb_todo_idx = 0;
  PUSH_BB_TODO(ENTRY_BLOCK_PTR_FOR_FN(cfun));
  while (bb_todo_idx > 0) {
    POP_BB_TODO(bb);
    PUSH_BB_DONE(bb);
    fprintf(stderr, "BB: %p\n", bb);
    for (gsi = gsi_start_bb(bb); !gsi_end_p(gsi); gsi_next(&gsi)) {
      fprintf(stderr, "    ");
      print_gimple_stmt(stderr, gsi_stmt(gsi), 0, TDF_DETAILS | TDF_VOPS);
    }

    FOR_EACH_EDGE(e, ei, bb->succs) {
      IS_BB_TODO(e->dest, is_bb_todo);
      if (is_bb_todo) {
        fprintf(stderr, "ED: %p: %p -> %p [todo]\n", bb, e->src, e->dest);
        PUSH_BB_TODO(e->dest);
      } else {
        fprintf(stderr, "ED: %p: %p -> %p\n", bb, e->src, e->dest);
      }
    }
  }
#if 0
  fprintf(stderr, "====\n");
  FOR_EACH_BB_FN(bb, cfun) {
    fprintf(stderr, "BB: %p\n", bb);
    for (gsi = gsi_start_bb(bb); !gsi_end_p(gsi); gsi_next(&gsi)) {
      fprintf(stderr, "    ");
      print_gimple_stmt(stderr, gsi_stmt(gsi), 0, TDF_DETAILS | TDF_VOPS);
    }

    FOR_EACH_EDGE(e, ei, bb->succs) {
      fprintf(stderr, "ED: %p: %p -> %p\n", bb, e->src, e->dest);
    }
  }
#endif
}

void gimple_harden_pointer_call(tree ptr, tree guard) {
  gimple_stmt_iterator gsi;
  gimple *stmt;
  edge e;
  edge_iterator ei;
  basic_block bb;
  int is_bb_todo;

  debug_print_graph();

  bb_done_idx = 0;
  bb_todo_idx = 0;
  PUSH_BB_TODO(ENTRY_BLOCK_PTR_FOR_FN(cfun));
  while (bb_todo_idx > 0) {
    POP_BB_TODO(bb);
    PUSH_BB_DONE(bb);

    FOR_EACH_EDGE(e, ei, bb->succs) {
      IS_BB_TODO(e->dest, is_bb_todo);
      if (is_bb_todo) {
        PUSH_BB_TODO(e->dest);
      }
    }

    printf("PROCESS BLOCK %p\n", bb);
    for (gsi = gsi_start_bb(bb); !gsi_end_p(gsi); gsi_next(&gsi)) {
      stmt = gsi_stmt(gsi);
      if (gimple_harden_pointer_call_aux(ptr, stmt)) {
        fprintf(stderr, "  DO CALL\n");
        fprintf(stderr, "    ");
        print_gimple_stmt(stderr, stmt, 0, TDF_DETAILS | TDF_VOPS);
        location_t loc = gimple_location (stmt);
        // insert_if_then_before_iter
        basic_block then_bb, fallthru_bb;
        fprintf(stderr, "  STEP1\n");
        gimple_stmt_iterator gsi_orig = gsi;

        //tree val1 = build_int_cst(integer_type_node, 0xa);
        //tree val2 = build_int_cst(integer_type_node, 0x1);
        tree val1 = create_tmp_var(integer_type_node, "__GUARD_TMP1");
        gimple* new_stmt1 = gimple_build_assign(val1, ptr);
        gsi_insert_after(&gsi, new_stmt1, GSI_NEW_STMT);
        tree val2 = create_tmp_var(integer_type_node, "__GUARD_TMP2");
        gimple* new_stmt2 = gimple_build_assign(val2, guard);
        gsi_insert_after(&gsi, new_stmt2, GSI_NEW_STMT);

        gimple_stmt_iterator cond_insert_point = create_cond_insert_point(&gsi, 0/*before_p*/, false, true, &then_bb, &fallthru_bb);
        gcond* g = gimple_build_cond(NE_EXPR, val1, val2, NULL_TREE, NULL_TREE);
        gsi_insert_after(&cond_insert_point, g, GSI_NEW_STMT);

        PUSH_BB_DONE(then_bb);
        PUSH_BB_DONE(fallthru_bb);

        // Call exit...
        gsi = gsi_after_labels (then_bb);
        // TEST: gimple* new_stmt = gimple_build_assign(guard, ptr);
        tree proto = build_function_type_list(
            void_type_node, // return type
            NULL_TREE       // varargs terminator
            );
        tree decl = build_fn_decl("exit", proto);
        gcall* new_stmt = gimple_build_call(decl, 0);
        gsi_insert_after(&gsi, new_stmt, GSI_NEW_STMT);

        fprintf(stderr, "    ");
        print_gimple_stmt(stderr, gsi_stmt(cond_insert_point), 0, TDF_DETAILS | TDF_VOPS);

        unlink_stmt_vdef(stmt);
        gsi_remove (&gsi_orig, true);
        gsi = gsi_start_bb(fallthru_bb);
        gsi_insert_before(&gsi, stmt, GSI_NEW_STMT);

        fprintf(stderr, "  STEP2\n");

        for (gsi = gsi_start_bb(bb); !gsi_end_p(gsi); gsi_next(&gsi)) {
          fprintf(stderr, "    ");
          print_gimple_stmt(stderr, gsi_stmt(gsi), 0, TDF_DETAILS | TDF_VOPS);
        }

        fprintf(stderr, "  STEP3\n");

        for (gsi = gsi_start_bb(then_bb); !gsi_end_p(gsi); gsi_next(&gsi)) {
          fprintf(stderr, "    ");
          print_gimple_stmt(stderr, gsi_stmt(gsi), 0, TDF_DETAILS | TDF_VOPS);
        }

        fprintf(stderr, "  STEP4\n");

        for (gsi = gsi_start_bb(fallthru_bb); !gsi_end_p(gsi); gsi_next(&gsi)) {
          fprintf(stderr, "    ");
          print_gimple_stmt(stderr, gsi_stmt(gsi), 0, TDF_DETAILS | TDF_VOPS);
        }

        fprintf(stderr, "  STEP5\n");

        for (; !gsi_end_p(gsi); gsi_next(&gsi)) {
          fprintf(stderr, "    ");
          print_gimple_stmt(stderr, gsi_stmt(gsi), 0, TDF_DETAILS | TDF_VOPS);
        }

        fprintf(stderr, "  STEP6\n");
        fprintf(stderr, "\n\n\n\n");

        gsi = gsi_start_bb(fallthru_bb);
      }
    }
  }
  cgraph_edge::rebuild_references ();
  cgraph_edge::rebuild_edges ();
  debug_print_graph();
}

// ###################

tree gimple_new_int_var(char* name) {
  tree var = build_decl (UNKNOWN_LOCATION, VAR_DECL, get_identifier(name), integer_type_node);
  TREE_ADDRESSABLE(var) = true;
  TREE_USED(var) = true;
  TREE_CHAIN(var) = NULL_TREE;
  DECL_INITIAL(var) = build_int_cst(integer_type_node, 0x11223344);
  return var;
}

void rtl_iterate(void){
  rtx_insn *insn = get_insns();
  print_rtl(stderr, insn);
  return;
  rtx_insn *last_insn = NEXT_INSN(get_last_insn());
  fprintf(stderr, "\n\n\n\n\n");
  fprintf(stderr, "H1\n");
  for (; insn != last_insn; insn = NEXT_INSN(insn)) {
    print_rtl_single(stderr, insn);
    if (INSN_P(insn)) {
      if (1) {
        pretty_printer pp;
        pp.buffer->stream = stdout;
        print_insn(&pp, insn, 0);
        pp_write_text_to_stream(&pp);
        fprintf(stderr, "\n");
        rtx subexp = XEXP(insn,5);
        int rt_code = GET_CODE(insn);
        fprintf(stderr, "code: %d [%d]\n", rt_code, SET);
        fprintf(stderr, "code: %d [%d]\n", rt_code, INSN);

        fprintf (stderr, "!! %s\n", GET_RTX_NAME (GET_CODE (insn)));
        const char *format_ptr = GET_RTX_FORMAT (GET_CODE (insn));
        fprintf(stderr, "%c\n\n", format_ptr[5]);
      }
    }
  }
}

const pass_data gimple_harden_pointers_data = {
  GIMPLE_PASS,
  "gimple_harden_pointers;", /* name */
  OPTGROUP_NONE,      /* optinfo_flags */
  TV_NONE,            /* tv_id */
  PROP_gimple_any,    /* properties_required */
  0,                  /* properties_provided */
  0,                  /* properties_destroyed */
  0,                  /* todo_flags_start */
  0                   /* todo_flags_finish */
};

struct gimple_harden_pointers_pass : gimple_opt_pass {

  gimple_harden_pointers_pass(gcc::context *ctx) : gimple_opt_pass(gimple_harden_pointers_data, ctx) {
  }

  virtual unsigned int execute(function *fun) override {
    fprintf(stderr, "=== BEGIN: gimple_harden_pointers_pass_execute:\n");
    fprintf(stderr, "execute %p %p\n", fun, cfun);
    fprintf(stderr, "cfg: %p\n", fun->cfg);

    tree ptrs[1024];
    tree guards[1024];
    int nb_ptrs = 0;

    tree var;
    unsigned int i;
    FOR_EACH_LOCAL_DECL(cfun, i, var) {
      if (DECL_NAME(var)) {
        fprintf(stderr, "var: %s\n", FN_NAME(var));
        tree type = TREE_TYPE(var);
        if (TREE_CODE(type) == POINTER_TYPE) {
          fprintf(stderr, "find pointer: %s\n", get_name(var));
          if (gimple_can_harden_pointer(var)) {
            gcc_assert(nb_ptrs < sizeof(ptrs)/sizeof(tree));
            ptrs[nb_ptrs] = var;
            nb_ptrs++;
          } else {
            fprintf(stderr, "cannot harden pointer: %s\n", get_name(var));
          }
        }
      } else {
        fprintf(stderr, "var unkown: %s\n", get_name(var));
      }
    }

    for (int i = 0; i < nb_ptrs; i++) {
      char name[16];
      sprintf(name, "%s__guard", get_name(ptrs[i]));
      guards[i] = gimple_new_int_var(name);
      add_local_decl(cfun, guards[i]);
      //debug_tree(guards[i]);
      gimple* new_stmt = gimple_build_assign(guards[i], build_int_cst(integer_type_node, 0x11223344));
      basic_block bb = ENTRY_BLOCK_PTR_FOR_FN(cfun);
      bb = bb->next_bb;
      gimple_stmt_iterator gsi = gsi_start_bb(bb);
      gsi_insert_before(&gsi, new_stmt, GSI_NEW_STMT);
      gimple_harden_pointer_assign(ptrs[i], guards[i]);
      gimple_harden_pointer_call(ptrs[i], guards[i]);
    }

    FOR_EACH_LOCAL_DECL(cfun, i, var) {
      if (DECL_NAME(var)) {
        fprintf(stderr, "var: %s\n", FN_NAME(var));
      } else {
        fprintf(stderr, "var unkown: %s\n", get_name(var));
        //debug_tree(var);
      }
    }

    gimple_stmt_iterator gsi;
    gimple *stmt;
    basic_block bb;
    FOR_EACH_BB_FN(bb, cfun) {
      for (gsi = gsi_start_bb(bb); !gsi_end_p(gsi); gsi_next(&gsi)) {
        stmt = gsi_stmt(gsi);
        debug_gimple_stmt(stmt);
      }
    }

    fprintf(stderr, "===== END: gimple_harden_pointers_pass_execute\n");
    return 0;
  }

  virtual gimple_harden_pointers_pass* clone() override {
    return this;
  }

  private:

  static tree callback_stmt(gimple_stmt_iterator * gsi, bool *handled_all_ops, struct walk_stmt_info *wi) {
    gimple* g = gsi_stmt(*gsi);
    location_t l = gimple_location(g);
    enum gimple_code code = gimple_code(g);
    print_gimple_stmt(stderr, g, 0, TDF_DETAILS | TDF_VOPS);
    fprintf(stderr, "Statement of type: %s at %s:%d\n", gimple_code_name[code], LOCATION_FILE(l), LOCATION_LINE(l));
    return NULL;
  }

  static tree callback_op(tree *t, int *, void *data) {
    enum tree_code code = TREE_CODE(*t);
    fprintf(stderr, "   Operand: %s\n", get_tree_code_name(code));
    return NULL;
  }

};

gimple_harden_pointers_pass gimple_harden_pointers = gimple_harden_pointers_pass(g);

const pass_data rtl_harden_pointers_data = {
  RTL_PASS,
  "rtl_harden_pointers;", /* name */
  OPTGROUP_NONE,      /* optinfo_flags */
  TV_NONE,            /* tv_id */
  PROP_gimple_any,    /* properties_required */
  0,                  /* properties_provided */
  0,                  /* properties_destroyed */
  0,                  /* todo_flags_start */
  0                   /* todo_flags_finish */
};

struct rtl_harden_pointers_pass : rtl_opt_pass {

  rtl_harden_pointers_pass(gcc::context *ctx) : rtl_opt_pass(rtl_harden_pointers_data, ctx) {
  }

  // void add_local_decl (struct function *fun, tree d);
  virtual unsigned int execute(function *fun) override {
    fprintf(stderr, "=== BEGIN: rtl_harden_pointers_pass_execute:\n");
    fprintf(stderr, "> inspecting function '%s'\n", FN_NAME(current_function_decl));
    basic_block entry = ENTRY_BLOCK_PTR_FOR_FN(cfun)->next_bb;
    debug_tree(current_function_decl);
    int code; 
    for (code = 0; code < 1000; code++) {
      name = get_insn_name(code);
    }
    fprintf(stderr, "=\n\n\n\n");
    rtx_insn *insn;
    for (insn = BB_HEADER(entry); insn; insn = NEXT_INSN(insn)) {
      print_rtl_single(stdout, insn);
    }
    rtl_iterate();

    fprintf(stderr, "===== END: rtl_harden_pointers_pass_execute\n");
    return 0;
  }

  virtual rtl_harden_pointers_pass* clone() override {
    return this;
  }
};

rtl_harden_pointers_pass rtl_harden_pointers = rtl_harden_pointers_pass(g);

static void handler_pre_genericize(void *event_data, void *user_data) {
  fprintf(stderr, "=== BEGIN: handler_pre_genericize:\n");
  tree t = (tree) event_data;
  fprintf(stderr, "code name: %s\n", get_tree_code_name(TREE_CODE(t)));
  fprintf(stderr, "is function? %d\n", TREE_CODE(t) == FUNCTION_DECL);
  if (TREE_CODE(t) == FUNCTION_DECL) {
    //debug_tree(DECL_SAVED_TREE(t));
    gimple_process_function_body(DECL_SAVED_TREE(t));
  }
  fprintf(stderr, "===== END: handler_pre_genericize\n");
}

static void handler_finish_type(void *event_data, void *data) {
  fprintf(stderr, "=== BEGIN: handler_finish_type:\n");
  tree type = (tree) event_data;
  debug_tree(type);
  fprintf(stderr, "===== END: handler_finish_type\n");
}

static void handler_finish_decl(void *event_data, void *data) {
  fprintf(stderr, "=== BEGIN: handler_finish_decl:\n");
  tree decl = (tree) event_data;
  debug_tree(decl);
  gcc_assert(TREE_CODE(decl) == VAR_DECL);
  tree id = DECL_NAME(decl);
  tree type = TREE_TYPE(decl);
  if (TREE_CODE(type) == POINTER_TYPE) {
    fprintf(stderr, "new pointer: %s\n", get_name(decl));
  }
  fprintf(stderr, "===== END: handler_finish_decl\n");
}

static void handler_global_variables(void *event_data, void *data) {
  fprintf(stderr, "=== BEGIN: handler_global_variables:\n");
  struct varpool_node *node;
  tree init;

  FOR_EACH_VARIABLE(node) {
    tree var = node->decl;
    debug_tree(var);
  }
  fprintf(stderr, "===== END: handler_global_variables\n");
}

int plugin_init(struct plugin_name_args *plugin_info, struct plugin_gcc_version *version) {
  register_callback(plugin_info->base_name, PLUGIN_PRE_GENERICIZE, handler_pre_genericize, NULL);
  //register_callback(plugin_info->base_name, PLUGIN_FINISH_TYPE, handler_finish_type, NULL);
  //register_callback(plugin_info->base_name, PLUGIN_ALL_IPA_PASSES_START, handler_global_variables, NULL);
  //register_callback(plugin_info->base_name, PLUGIN_FINISH_DECL, handler_finish_decl, NULL);

  struct register_pass_info gimple_pass;
  gimple_pass.pass = &gimple_harden_pointers;

  // get called after Control flow graph cleanup (see gimple passes)  
  gimple_pass.reference_pass_name = "optimized";
  gimple_pass.reference_pass_name = "ssa";

  gimple_pass.ref_pass_instance_number = 1;
  gimple_pass.pos_op = PASS_POS_INSERT_AFTER;
  gimple_pass.pos_op = PASS_POS_INSERT_BEFORE;
  register_callback(plugin_info->base_name, PLUGIN_PASS_MANAGER_SETUP, NULL, &gimple_pass);

  struct register_pass_info rtl_pass;
  rtl_pass.pass = &rtl_harden_pointers;

  // get called after Control flow graph cleanup (see RTL passes)  
  rtl_pass.reference_pass_name = "omplower";
  rtl_pass.reference_pass_name = "tmlower";
  rtl_pass.reference_pass_name = "reginfo";
  rtl_pass.reference_pass_name = "vregs";
  rtl_pass.reference_pass_name = "expand";
  rtl_pass.reference_pass_name = "optimized";
  rtl_pass.reference_pass_name = "ssa";
  rtl_pass.reference_pass_name = "*free_cfg";
  rtl_pass.reference_pass_name = "*rest_of_compilation";

  rtl_pass.ref_pass_instance_number = 1;
  rtl_pass.pos_op = PASS_POS_INSERT_AFTER;
  rtl_pass.pos_op = PASS_POS_INSERT_BEFORE;
  //register_callback(plugin_info->base_name, PLUGIN_PASS_MANAGER_SETUP, NULL, &rtl_pass);

  return 0;
}
