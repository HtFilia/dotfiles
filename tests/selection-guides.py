#!/usr/bin/env python3
"""Offline selection, installed-only documentation and custom binary checks."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import shutil
import platform
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
def load(name, filename):
    spec=importlib.util.spec_from_file_location(name,ROOT/'scripts'/filename)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
selector=load('selector','select-tools.py')
guides=load('guides','generate-agent-guides.py')


class SelectionAndGuides(unittest.TestCase):
    def setUp(self):
        temp=tempfile.TemporaryDirectory(prefix='dotfiles-selection-');self.addCleanup(temp.cleanup)
        self.home=Path(temp.name);self.bin=self.home/'bin';self.bin.mkdir()
        self.env=dict(os.environ,HOME=str(self.home),PATH=str(self.bin)+':/usr/bin:/bin',LOCAL_BIN=str(self.bin))
        for key in ('DOTFILES_TOOLS','DOTFILES_INSTALL_METHODS','DOTFILES_REPORT_DIR','GOBIN','GOPATH','CARGO_HOME'):
            self.env.pop(key,None)
    def executable(self,path,body='printf "sample 1.0.0\\n"'):
        path.parent.mkdir(parents=True,exist_ok=True);path.write_text('#!/bin/sh\n'+body+'\n');path.chmod(0o755);return path
    def run_cli(self,filename,*args,env=None):
        return subprocess.run([sys.executable,str(ROOT/'scripts'/filename),*args],env=env or self.env,text=True,capture_output=True,timeout=15)
    def test_recommended_defaults_are_small_and_exclude_visuals_and_sdks(self):
        selected=selector.resolve('recommended',selector.platform_tools())
        self.assertEqual(len(selected),13)
        self.assertTrue(selector.REQUIRED<=set(selected))
        self.assertFalse(set(selected)&{'go','rustc','cargo','cmatrix','cava','viu','node','docker'})
    def test_prerequisites_remain_selected_with_none(self):
        self.assertEqual(set(selector.resolve('none',selector.platform_tools())),selector.REQUIRED)
    def test_explicit_selection_does_not_pull_in_unrequested_tools(self):
        self.assertEqual(set(selector.resolve('rg,jq',selector.platform_tools())),selector.REQUIRED|{'rg','jq'})
    def test_invalid_selection_writes_nothing(self):
        result=self.run_cli('select-tools.py','--tools','nonexistent','--save')
        self.assertEqual(result.returncode,2);self.assertFalse((self.home/'.local').exists())
    def test_picker_can_disable_both_fallbacks(self):
        answers=iter(['none','source','n','n'])
        with contextlib.redirect_stderr(io.StringIO()):
            selected,order=selector.interactive(selector.platform_tools(),[],['native','github'],lambda:next(answers))
        self.assertEqual(order,['source']);self.assertEqual(set(selected),selector.REQUIRED)
    def test_picker_selects_by_number_and_respects_no_source_fallback(self):
        tools=selector.platform_tools();ordered=[t for category in selector.CATEGORIES for t in tools if t['category']==category]
        number=next(str(i+1) for i,t in enumerate(ordered) if t['name']=='jq')
        answers=iter([number,'github','n','n'])
        with contextlib.redirect_stderr(io.StringIO()):
            selected,order=selector.interactive(tools,[],['native'],lambda:next(answers))
        self.assertEqual(set(selected),selector.REQUIRED|{'jq'});self.assertEqual(order,['github'])
    def test_picker_can_extend_preset_without_removing_prerequisites(self):
        answers=iter(['recommended,+gh,-git,-fzf','native','y','n'])
        with contextlib.redirect_stderr(io.StringIO()):
            selected,order=selector.interactive(selector.platform_tools(),[],['native'],lambda:next(answers))
        self.assertIn('git',selected);self.assertIn('gh',selected);self.assertNotIn('fzf',selected)
        self.assertEqual(order,['native','github'])
    def test_saved_selection_is_reused_by_updates(self):
        result=self.run_cli('select-tools.py','--tools','jq','--methods','github','--save')
        self.assertEqual(result.returncode,0,result.stderr)
        again=self.run_cli('select-tools.py')
        self.assertEqual(json.loads(again.stdout),json.loads(result.stdout))
    def test_noninteractive_picker_fails_without_blocking(self):
        result=self.run_cli('select-tools.py','--interactive')
        self.assertEqual(result.returncode,2);self.assertIn('terminal',result.stderr)
    def test_interactive_cli_reads_a_real_terminal(self):
        master,slave=os.openpty()
        try:
            os.write(master,b'none\nnative\nn\nn\n')
            result=subprocess.run([sys.executable,str(ROOT/'scripts/select-tools.py'),'--interactive'],
                stdin=slave,stdout=subprocess.PIPE,stderr=subprocess.PIPE,env=self.env,text=True,timeout=10)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual(json.loads(result.stdout)['methods'],['native'])
            self.assertIn('fallback',result.stderr)
        finally:os.close(master);os.close(slave)
    def test_exclusions_are_saved_without_removing_prerequisites(self):
        result=self.run_cli('select-tools.py','--tools','recommended','--exclude','fzf,git','--save')
        self.assertEqual(result.returncode,0,result.stderr)
        data=json.loads(result.stdout);self.assertNotIn('fzf',data['tools']);self.assertIn('git',data['tools'])
        self.assertEqual(json.loads(self.run_cli('select-tools.py').stdout),data)
    def test_disabled_native_never_authenticates_or_installs_packages(self):
        installer=load('selection_installer','install-tools.py')
        with patch.dict(os.environ,self.env), patch.object(installer.os,'geteuid',return_value=1000):
            engine=installer.Installer(installer.Report(self.home/'report'),['github'])
            with patch.object(engine,'run') as run, patch.object(installer.subprocess,'run') as auth:
                engine.prepare_native([])
            run.assert_not_called();auth.assert_not_called()

    def test_failed_known_binary_is_omitted(self):
        self.executable(self.bin/'broken','exit 7')
        catalog=[dict(name='broken',bins=['broken'],description='Broken utility',usage='broken --help')]
        self.assertEqual(guides.inventory(catalog,[],self.env),[])
    def test_custom_go_rust_binaries_are_discovered_without_execution(self):
        marker=self.home/'executed'
        go=self.executable(self.home/'go/bin/company-go',f'touch "{marker}"; exit 8')
        rust=self.executable(self.home/'.cargo/bin/company-rust',f'touch "{marker}"; exit 9')
        rows=guides.inventory([],[],self.env)
        self.assertEqual({r['name'] for r in rows},{'company-go','company-rust'})
        self.assertFalse(marker.exists());self.assertTrue(all(not r['validated'] for r in rows))
    def test_custom_gobin_and_cargo_home_are_respected(self):
        env=dict(self.env,GOBIN=str(self.home/'custom-go'),CARGO_HOME=str(self.home/'custom-rust'))
        self.executable(self.home/'custom-go/client');self.executable(self.home/'custom-rust/bin/processor')
        self.assertEqual({r['name'] for r in guides.inventory([],[],env)},{'client','processor'})
    def test_registered_description_requires_an_actual_executable(self):
        self.executable(self.bin/'client')
        rows=guides.inventory([], [{'name':'client','description':'Data query CLI','usage':'client inspect'},
                                  {'name':'missing','description':'Should not appear'}], self.env)
        self.assertEqual(len(rows),1);self.assertEqual(rows[0]['description'],'Data query CLI')
        self.assertNotIn('missing',guides.render(rows))
    def test_installed_guide_does_not_list_failed_unselected_catalog(self):
        self.executable(self.bin/'good')
        catalog=[dict(name=n,bins=[n],description=n+' purpose',usage=n+' --help') for n in ('good','absent')]
        text=guides.render(guides.inventory(catalog,[],self.env))
        self.assertIn('good',text);self.assertNotIn('absent',text)
    def test_generation_replaces_old_symlink_without_changing_source(self):
        destination=self.home/'dest';destination.mkdir()
        old=self.home/'old-source';old.write_text('all tools static guide')
        (destination/'AGENTS.additional.md').symlink_to(old)
        registry=self.home/'custom.json';registry.write_text('[]')
        result=self.run_cli('generate-agent-guides.py','--destination',str(destination),'--custom-tools',str(registry))
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(old.read_text(),'all tools static guide')
        self.assertFalse((destination/'AGENTS.additional.md').is_symlink())
        self.assertEqual((destination/'AGENTS.additional.md').read_text(),(destination/'CLAUDE.additional.md').read_text())
    def test_custom_registry_path_is_remembered_for_regeneration(self):
        self.executable(self.bin/'company-client')
        registry=self.home/'custom-location.json'
        registry.write_text(json.dumps([dict(name='company-client',description='Custom data workflow',usage='company-client inspect')]))
        destination=self.home/'dest'
        first=self.run_cli('generate-agent-guides.py','--destination',str(destination),'--custom-tools',str(registry))
        again=self.run_cli('generate-agent-guides.py','--destination',str(destination))
        self.assertEqual(first.returncode,0,first.stderr);self.assertEqual(again.returncode,0,again.stderr)
        self.assertIn('Custom data workflow',(destination/'AGENTS.additional.md').read_text())

    def test_dry_run_does_not_write_guides_or_inventory(self):
        destination=self.home/'dest'
        result=self.run_cli('generate-agent-guides.py','--destination',str(destination),'--dry-run')
        self.assertEqual(result.returncode,0,result.stderr);self.assertFalse(destination.exists())
    def test_invalid_registry_cannot_write_guides(self):
        path=self.home/'bad.json';path.write_text('{"command":"danger"}')
        result=self.run_cli('generate-agent-guides.py','--custom-tools',str(path))
        self.assertEqual(result.returncode,2);self.assertFalse((self.home/'AGENTS.additional.md').exists())
    def test_default_bootstrap_preview_accepts_empty_optional_arguments(self):
        result=subprocess.run(['bash',str(ROOT/'scripts/bootstrap.sh'),'--dry-run'],
                              env=self.env,text=True,capture_output=True,timeout=15)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertIn('jq: native',result.stdout)
        self.assertFalse((self.home/'.local/state/dotfiles/tool-selection.json').exists())
    def test_update_reuses_saved_selection_through_the_single_installer(self):
        saved=self.run_cli('select-tools.py','--tools','none','--methods','github','--save')
        self.assertEqual(saved.returncode,0,saved.stderr)
        result=subprocess.run(['bash',str(ROOT/'scripts/update-tools.sh'),'--profile','workstation','--dry-run'],
                              env=self.env,text=True,capture_output=True,timeout=15)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertIn('install-tools.py',result.stdout)
        self.assertIn('--methods github',result.stdout)
        self.assertNotIn('apt-get',result.stdout)

    def test_bootstrap_preview_resolves_only_selected_tools_and_policy(self):
        result=subprocess.run(['bash',str(ROOT/'scripts/bootstrap.sh'),'--tools','jq','--install-methods','github','--dry-run'],env=self.env,text=True,capture_output=True,timeout=15)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertIn('jq: github;',result.stdout);self.assertNotIn('cmatrix:',result.stdout)
        self.assertFalse((self.home/'.local/state/dotfiles/tool-selection.json').exists())


if __name__=='__main__':unittest.main(verbosity=2)
