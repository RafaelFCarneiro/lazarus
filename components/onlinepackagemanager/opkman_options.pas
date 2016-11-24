unit opkman_options;

{$mode objfpc}{$H+}

interface

{
 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************

 Author: Balázs Székely
}
uses
  Classes, SysUtils, LazIDEIntf, Laz2_XMLCfg, LazFileUtils;

type
  { TOptions }
  TProxySettings = record
    FEnabled: boolean;
    FServer: string;
    FPort: Word;
    FUser: string;
    FPassword: string;
  end;

  TOptions = class
   private
     FProxySettings: TProxySettings;
     FXML: TXMLConfig;
     FRemoteRepository: String;
     FChanged: Boolean;
     FLastDownloadDir: String;
     FLastPackageDirSrc: String;
     FLastPackageDirDst: String;
     FRestrictedExtensions: String;
     FRestrictedDirectories: String;
     FLocalRepositoryPackages: String;
     FLocalRepositoryArchive: String;
     FLocalRepositoryUpdate: String;
     procedure SetRemoteRepository(const ARemoteRepository: String);
   public
     constructor Create(const AFileName: String);
     destructor Destroy; override;
   public
     procedure Save;
     procedure Load;
     procedure LoadDefault;
   published
     property Changed: Boolean read FChanged write FChanged;
     property LastDownloadDir: String read FLastDownloadDir write FLastDownloadDir;
     property LastPackagedirSrc: String read FLastPackageDirSrc write FLastPackageDirSrc;
     property LastPackagedirDst: String read FLastPackageDirDst write FLastPackageDirDst;
     property RemoteRepository: string read FRemoteRepository write SetRemoteRepository;
     property ProxyEnabled: Boolean read FProxySettings.FEnabled write FProxySettings.FEnabled;
     property ProxyServer: String read FProxySettings.FServer write FProxySettings.FServer;
     property ProxyPort: Word read FProxySettings.FPort write FProxySettings.FPort;
     property ProxyUser: String read FProxySettings.FUser write FProxySettings.FUser;
     property ProxyPassword: String read FProxySettings.FPassword write FProxySettings.FPassword;
     property RestrictedExtension: String read FRestrictedExtensions write FRestrictedExtensions;
     property RestrictedDirectories: String read FRestrictedDirectories write FRestrictedDirectories;
     property LocalRepositoryPackages: String read FLocalRepositoryPackages write FLocalRepositoryPackages;
     property LocalRepositoryArchive: String read FLocalRepositoryArchive write FLocalRepositoryArchive;
     property LocalRepositoryUpdate: String read FLocalRepositoryUpdate write FLocalRepositoryUpdate;
  end;

var
  Options: TOptions = nil;

implementation
uses opkman_const;

{ TOptions }

constructor TOptions.Create(const AFileName: String);
begin
  FXML := TXMLConfig.Create(AFileName);
  if FileExists(AFileName) then
    Load
  else
    LoadDefault;
  end;

destructor TOptions.Destroy;
begin
  if FChanged then
    Save;
  FXML.Free;
  inherited Destroy;
end;

procedure TOptions.Load;
begin
  FRemoteRepository := FXML.GetValue('General/RemoteRepository/Value', '');
  FLastDownloadDir := FXML.GetValue('General/LastDownloadDir/Value', '');
  FLastPackageDirSrc := FXML.GetValue('General/LastPackageDirSrc/Value', '');
  FLastPackageDirDst := FXML.GetValue('GeneralLastPackageDirDst/Value', '');

  FProxySettings.FEnabled := FXML.GetValue('Proxy/Enabled/Value', False);
  FProxySettings.FServer := FXML.GetValue('Proxy/Server/Value', '');
  FProxySettings.FPort := FXML.GetValue('Proxy/Port/Value', 0);
  FProxySettings.FUser := FXML.GetValue('Proxy/User/Value', '');
  FProxySettings.FPassword := FXML.GetValue('Proxy/Password/Value', '');

  FLocalRepositoryPackages := FXML.GetValue('Folders/LocalRepositoryPackages/Value', '');
  FLocalRepositoryArchive := FXML.GetValue('Folders/LocalRepositoryArchive/Value', '');
  FLocalRepositoryUpdate := FXML.GetValue('Folders/LocalRepositoryUpdate/Value', '');
end;

procedure TOptions.Save;
begin
  FXML.SetDeleteValue('General/RemoteRepository/Value', FRemoteRepository, '');
  FXML.SetDeleteValue('General/LastDownloadDir/Value', FLastDownloadDir, '');
  FXML.SetDeleteValue('General/LastPackageDirSrc/Value', FLastPackageDirSrc, '');
  FXML.SetDeleteValue('LastPackageDirDst/Value', FLastPackageDirDst, '');

  FXML.SetDeleteValue('Proxy/Enabled/Value', FProxySettings.FEnabled, false);
  FXML.SetDeleteValue('Proxy/Server/Value', FProxySettings.FServer, '');
  FXML.SetDeleteValue('Proxy/Port/Value', FProxySettings.FPort, 0);
  FXML.SetDeleteValue('Proxy/User/Value', FProxySettings.FUser, '');
  FXML.SetDeleteValue('Proxy/Password/Value', FProxySettings.FPassword, '');

  FXML.SetDeleteValue('Folders/LocalRepositoryPackages/Value', FLocalRepositoryPackages, '');
  FXML.SetDeleteValue('Folders/LocalRepositoryArchive/Value', FLocalRepositoryArchive, '');
  FXML.SetDeleteValue('Folders/LocalRepositoryUpdate/Value', FLocalRepositoryUpdate, '');

  FXML.Flush;
  FChanged := False;
end;

procedure TOptions.LoadDefault;
var
  LocalRepository: String;
begin
  FRemoteRepository := 'http://packages.lazarus-ide.org/';

  FProxySettings.FEnabled := False;
  FProxySettings.FServer := '';
  FProxySettings.FPort := 0;
  FProxySettings.FUser := '';
  FProxySettings.FPassword := '';

  LocalRepository := AppendPathDelim(AppendPathDelim(LazarusIDE.GetPrimaryConfigPath) + cLocalRepository);
  FLocalRepositoryPackages := LocalRepository + AppendPathDelim(cLocalRepositoryPackages);
  if not DirectoryExists(FLocalRepositoryPackages) then
    CreateDir(FLocalRepositoryPackages);
  FLocalRepositoryArchive := LocalRepository + AppendPathDelim(cLocalRepositoryArchive);
  if not DirectoryExistsUTF8(FLocalRepositoryArchive) then
    CreateDirUTF8(FLocalRepositoryArchive);
  FLocalRepositoryUpdate := LocalRepository + AppendPathDelim(cLocalRepositoryUpdate);
  if not DirectoryExists(FLocalRepositoryUpdate) then
    CreateDir(FLocalRepositoryUpdate);

  FRestrictedExtensions := '*.a,*.o,*.ppu,*.compiled,*.bak,*.or,*.rsj,*.~ ';
  FRestrictedDirectories := 'lib,backup';
  Save;
end;

procedure TOptions.SetRemoteRepository(const ARemoteRepository: String);
begin
  if FRemoteRepository <> ARemoteRepository then
  begin
    FRemoteRepository := Trim(ARemoteRepository);
    if FRemoteRepository[Length(FRemoteRepository)] <> '/' then
      FRemoteRepository := FRemoteRepository + '/';
  end;
end;

end.
