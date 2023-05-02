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
#include "gimplify.h"
#include "diagnostic-core.h"
#include <cgraph.h>
#include <asan.h>
#include <tree-ssa-operands.h>

#define FN_NAME(t) IDENTIFIER_POINTER(DECL_NAME(t))

int plugin_is_GPL_compatible; // must be defined & exported for the plugin to be loaded

extern gcc::context *g;

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

const char* memcpy_name = "__memcpy_ichk"; //__memcpy_ichk
const char* test_name = "printk";
int last_tree;
location_t last_loc;

struct gimple_harden_pointers_pass : gimple_opt_pass {

  gimple_harden_pointers_pass(gcc::context *ctx) : gimple_opt_pass(gimple_harden_pointers_data, ctx) {
  }

  virtual unsigned int execute(function *fun) override {
    gimple_stmt_iterator gsi;
    gimple *stmt;
    basic_block bb;
    FOR_EACH_BB_FN(bb, cfun) {
      for (gsi = gsi_start_bb(bb); !gsi_end_p(gsi); gsi_next(&gsi)) {
        stmt = gsi_stmt(gsi);     
        if(gimple_code(stmt) == GIMPLE_ASSIGN) {
          enum tree_code code = gimple_expr_code(stmt);
          if(code == 74) { // 74
            last_tree = SSA_NAME_VERSION(gimple_op(stmt, 0));
            last_loc = gimple_location(stmt);
          }
        }
        if(gimple_code(stmt) == GIMPLE_CALL){
          tree current_fn_decl = gimple_call_fn(stmt);
          if(current_fn_decl != NULL) {
            const char* name = get_name(current_fn_decl);
            if(name) {
              //fprintf(stderr, "%s\n", name);
              if(!strcmp(memcpy_name, name)) {
                tree arg = gimple_call_arg(stmt, 1);
                enum tree_code code = TREE_CODE(arg);
                if(code == SSA_NAME && SSA_NAME_VERSION(arg) == last_tree) {
                  location_t loc = gimple_location(stmt);
                  // 687 = Woverflow
                  warning_at(last_loc, 687, "starting memcpy after beginning of buffer will result in a crash on the CV32A6 processor");
                }
              }
            }
          }
        }
      }
    }
    return 0;
  }

  virtual gimple_harden_pointers_pass* clone() override {
    return this;
  }

};

gimple_harden_pointers_pass gimple_harden_pointers = gimple_harden_pointers_pass(g);

int plugin_init(struct plugin_name_args *plugin_info, struct plugin_gcc_version *version) {
  struct register_pass_info gimple_pass;
  gimple_pass.pass = &gimple_harden_pointers;

  // get called after Control flow graph cleanup (see gimple passes)  
  gimple_pass.reference_pass_name = "optimized";
  gimple_pass.reference_pass_name = "ssa";

  gimple_pass.ref_pass_instance_number = 1;
  gimple_pass.pos_op = PASS_POS_INSERT_AFTER;
  gimple_pass.pos_op = PASS_POS_INSERT_BEFORE;
  register_callback(plugin_info->base_name, PLUGIN_PASS_MANAGER_SETUP, NULL, &gimple_pass);

  return 0;
}
