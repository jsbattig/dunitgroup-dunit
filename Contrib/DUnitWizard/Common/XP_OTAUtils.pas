unit XP_OTAUtils;

{
 $Source: /cvsroot/dunit/dunit/Contrib/DUnitWizard/Common/XP_OTAUtils.pas,v $
 $Revision: 1.1 $
 $Date: 2003/01/27 12:48:28 $
 Last amended by $Author: pvspain $
 $State: Exp $

 XP_OTAUtils:
 Utility methods and base classes for OpenTools API

 Copyright (c) 2001,2002 by The Excellent Programming Company Pty Ltd
 (ABN 27 005 394 918). All rights reserved.

 Contact Paul Spain via email: paul@xpro.com.au

 This unit is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This unit is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this unit; if not, the license can be viewed at:
 http://www.gnu.org/copyleft/lesser.html
 or write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 Boston, MA  02111-1307  USA
 }

interface

uses
  ToolsAPI, SysUtils;

function AskFileName(const Caption: string;
  var AbsoluteFileSpec: string): boolean;

function ExtractWhiteSpace(const AString: string): string;
function ExtractFileStem(const AFileName: string): string;

procedure MessageViewAdd(AMessage: string);
procedure MessageViewAddFmt(const MessageFormat: string;
  const Args: array of const);

function IsMetaModule(const AModule: IOTAModule): boolean;

function GetCurrentUnitName(out AbsoluteFileSpec: string): boolean;
function GetCurrentProjectName(out AbsoluteFileSpec: string): boolean;
function GetCurrentProjectGroupName(out AbsoluteFileSpec: string): boolean;

function GetCurrentSourceEditor(out SourceEditor: IOTASourceEditor): boolean;

function GetCurrentProject(out Project: IOTAProject): boolean;
function GetCurrentProjectGroup(out ProjectGroup: IOTAProjectGroup): boolean;

function CreateModule(const Creator: IOTACreator): boolean;

function AddWizard(const Wizard: IOTAWizard; out Handle: integer): boolean;
procedure DeleteWizard(const Handle: integer);

//////////////////////////////////////////////////////////////////////////////
///     TXP_OTAFile declaration
//////////////////////////////////////////////////////////////////////////////

type

  IXP_OTAFile = interface(IOTAFile)
    ['{709205C1-C959-48EA-A58B-F74DE1059F50}']
    function GetFileName: string;
    procedure SetFileName(const AFileName: string);

    property FileName: string
      read GetFileName write SetFileName;
  end;

  TXP_OTAFile = class (TInterfacedObject, IOTAFile, IXP_OTAFile)
  protected

    FFileName: string;

    function GetSource: string; virtual; abstract;
    function GetAge: TDateTime; virtual;

    function GetFileName: string; virtual;
    procedure SetFileName(const AFileName: string); virtual;

  public

    constructor Create(const AFileName: string = ''); virtual;

  end;


implementation

uses
  XP_OTAFileNamer,        // TXP_OTAProjectNamerForm dialogue
  Forms,                     // Application, mrOK
  FileCtrl,                  // ForceDirectories
  Controls;                  // mrOK

const
  CVSID: string = '$Header: /cvsroot/dunit/dunit/Contrib/DUnitWizard/Common/XP_OTAUtils.pas,v 1.1 2003/01/27 12:48:28 pvspain Exp $';

var
  FileNamerForm: TXP_OTAFileNamerForm;

function AskFileName(const Caption: string;
  var AbsoluteFileSpec: string): boolean;
begin

  if not System.Assigned(FileNamerForm) then
    // Don't assign owner since we need to manage destruction. If
    // this unit is in a package it may be unloaded at any stage -
    // if we assign an Owner, our destructor code may not be available
    // when the Owner is destroying its children.
    FileNamerForm := TXP_OTAFileNamerForm.Create(nil);

  FileNamerForm.Caption := Caption;
  FileNamerForm.FileName := AbsoluteFileSpec;
  Result := FileNamerForm.ShowModal = mrOK;

  if Result then
  begin
    // Create folder(s) as required
    FileCtrl.ForceDirectories(SysUtils.ExcludeTrailingBackslash(
      SysUtils.ExtractFilePath(FileNamerForm.FileName)));
    AbsoluteFileSpec := FileNamerForm.FileName;
  end;

end;

function ExtractWhiteSpace(const AString: string): string;
var
  Src, Dst: pchar;

begin
  System.SetLength(Result, System.Length(AString));

  if System.Length(Result) > 0 then
  begin
    Src := @AString[1];
    Dst := @Result[1];

    while Src^ <> #0 do
    begin

      if not (Src^ in [#09..#13, #32]) then
      begin
        Dst^ := Src^;
        System.Inc(Dst);
      end;

      System.Inc(Src);
    end;

    // Copy null terminator (#0);
    Dst^ := Src^;
    // Copy to new string, length based on position of null terminator
    Result := pchar(Result);
  end;

end;

function ExtractFileStem(const AFileName: string): string;
begin
  Result := SysUtils.ChangeFileExt( SysUtils.ExtractFileName(AFileName), '' );
end;

procedure MessageViewAdd(AMessage: string);
var
  MessageServices: IOTAMessageServices;

begin

  if SysUtils.Supports(BorlandIDEServices, IOTAMessageServices,
    MessageServices) then
    MessageServices.AddTitleMessage(AMessage);

end;

procedure MessageViewAddFmt(const MessageFormat: string;
  const Args: array of const);
begin
  MessageViewAdd(SysUtils.Format(MessageFormat, Args));
end;

function IsMetaModule(const AModule: IOTAModule): boolean;
var
  Project: IOTAProject;
  ProjectGroup: IOTAProjectGroup;

begin
  Result := SysUtils.Supports(AModule, IOTAProject, Project)
    or SysUtils.Supports(AModule, IOTAProjectGroup, ProjectGroup);
end;

function GetCurrentUnitName(out AbsoluteFileSpec: string): boolean;
var
  SourceEditor: IOTASourceEditor;

begin
  Result := GetCurrentSourceEditor(SourceEditor);

  if Result then
    AbsoluteFileSpec := SourceEditor.FileName
  else
    AbsoluteFileSpec := '';

end;

function GetCurrentProjectName(out AbsoluteFileSpec: string): boolean;
var
  Project: IOTAProject;

begin
  Result := GetCurrentProject(Project);

  if Result then
    AbsoluteFileSpec := Project.FileName
  else
    AbsoluteFileSpec := '';

end;

function GetCurrentProjectGroupName(out AbsoluteFileSpec: string): boolean;
var
  ProjectGroup: IOTAProjectGroup;

begin
  Result := GetCurrentProjectGroup(ProjectGroup);

  if Result then
    AbsoluteFileSpec := ProjectGroup.FileName
  else
    AbsoluteFileSpec := '';

end;

function GetCurrentSourceEditor(out SourceEditor: IOTASourceEditor): boolean;
var
  ModuleServices: IOTAModuleServices;
  Module: IOTAModule;
  idx: integer;

begin
  Result := false;
  SourceEditor := nil;

  if SysUtils.Supports(BorlandIDEServices, IOTAModuleServices,
    ModuleServices) then
  begin
    Module := ModuleServices.CurrentModule;
    idx := Module.GetModuleFileCount - 1;

    // Iterate over modules till we find a source editor or list exhausted
    while not ((idx < 0) or SysUtils.Supports(Module.GetModuleFileEditor(idx),
      IOTASourceEditor, SourceEditor)) do
      System.Dec(idx);

    // Success if list wasn't ehausted.
    Result := idx >= 0;
  end;

end;

function GetCurrentProject(out Project: IOTAProject): boolean;
var
  ProjectGroup: IOTAProjectGroup;

begin

  if GetCurrentProjectGroup(ProjectGroup) then
    Project := ProjectGroup.GetActiveProject
  else
    Project := nil;

  Result := System.Assigned(Project);
end;

function GetCurrentProjectGroup(out ProjectGroup: IOTAProjectGroup): boolean;
var
  ModuleServices: IOTAModuleServices;
  idx: integer;

begin
  Result := false;
  ProjectGroup := nil;

  if SysUtils.Supports(BorlandIDEServices, IOTAModuleServices,
    ModuleServices) then
  begin
    idx := ModuleServices.ModuleCount - 1;

    // Iterate over modules till we find a project group or list exhausted
    while not ((idx < 0) or SysUtils.Supports(ModuleServices.Modules[idx],
      IOTAProjectGroup, ProjectGroup)) do
      System.Dec(idx);

    // Success if list wasn't ehausted.
    Result := idx >= 0;
  end;

end;

function CreateModule(const Creator: IOTACreator): boolean;
var
  ModuleServices: IOTAModuleServices;

begin
  Result :=  SysUtils.Supports(ToolsAPI.BorlandIDEServices, IOTAModuleServices,
    ModuleServices) and System.Assigned(Creator);

  if Result then
    ModuleServices.CreateModule(Creator);

end;

function AddWizard(const Wizard: IOTAWizard; out Handle: integer): boolean;
var
  WizardServices: IOTAWizardServices;

begin
  Result :=  SysUtils.Supports(ToolsAPI.BorlandIDEServices, IOTAWizardServices,
    WizardServices) and System.Assigned(Wizard);

  if Result then
    Handle := WizardServices.AddWizard(Wizard);

end;

procedure DeleteWizard(const Handle: integer);
var
  WizardServices: IOTAWizardServices;

begin

  if SysUtils.Supports(ToolsAPI.BorlandIDEServices, IOTAWizardServices,
    WizardServices) then
    WizardServices.RemoveWizard(Handle);

end;

//////////////////////////////////////////////////////////////////////////////
///     TXP_OTAFile implementation
//////////////////////////////////////////////////////////////////////////////

constructor TXP_OTAFile.Create(const AFileName: string);
begin
  inherited Create;
  SetFileName(AFileName);
end;

function TXP_OTAFile.GetAge: TDateTime;
begin
  // New file
  Result := -1;
end;

function TXP_OTAFile.GetFileName: string;
begin
  Result := FFileName
end;

procedure TXP_OTAFile.SetFileName(const AFileName: string);
begin
  FFileName := AFileName;
end;

initialization
finalization

  FileNamerForm.Free;

end.


