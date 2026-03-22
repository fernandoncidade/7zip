// AboutDialog.cpp

#include "StdAfx.h"

#include "../../../../C/CpuArch.h"

#include "../../MyVersion.h"

#include "../Common/LoadCodecs.h"

#include "AboutDialog.h"
#include "PropertyNameRes.h"

#include "HelpUtils.h"
#include "LangUtils.h"

#ifdef Z7_LANG
static const UInt32 kLangIDs[] =
{
  IDT_ABOUT_INFO,
  IDT_ABOUT_FORK_NOTE
};
#endif

#define kHomePageURL TEXT("https://www.7-zip.org/")
#define kForkRepoURL TEXT("https://github.com/fernandoncidade/7zip")
#define kHelpTopic "start.htm"

#define LLL_(quote) L##quote
#define LLL(quote) LLL_(quote)

extern CCodecs *g_CodecsObj;

bool CAboutDialog::OnInit()
{
  #ifdef Z7_EXTERNAL_CODECS
  if (g_CodecsObj)
  {
    UString s;
    g_CodecsObj->GetCodecsErrorMessage(s);
    if (!s.IsEmpty())
      MessageBoxW(GetParent(), s, L"7-Zip", MB_ICONERROR);
  }
  #endif

  #ifdef Z7_LANG
  LangSetWindowText(*this, IDD_ABOUT);
  LangSetDlgItems(*this, kLangIDs, Z7_ARRAY_SIZE(kLangIDs));
  #endif
  SetItemText(IDT_ABOUT_VERSION, UString("7-Zip " MY_VERSION_CPU));
  SetItemText(IDT_ABOUT_DATE, LLL(MY_DATE));
  SetItemText(IDT_ABOUT_FORK_VERSION, L"7-Zip 2026.3.19.0 (" LLL(MY_CPU_NAME) L")");
  SetItemText(IDT_ABOUT_FORK_DATE, L"19/03/2026");
  SetItemText(IDT_ABOUT_FORK_COPYRIGHT, L"Copyright (c) 2026 Fernando Nillsson Cidade");
  {
    UString s = LangString(IDT_ABOUT_INFO);
    if (s.IsEmpty())
      s = L"7-Zip is free software";
    SetItemText(IDT_ABOUT_FORK_INFO, s);
  }
  {
    UString s;
    #ifdef Z7_LANG
    LangString_OnlyFromLangFile(IDS_ABOUT_FORK_REPO, s);
    #endif
    if (s.IsEmpty())
      s = L"Repository: https://github.com/fernandoncidade/7zip";
    SetItemText(IDB_ABOUT_FORK_REPO, s);
  }
  
  NormalizePosition();
  return CModalDialog::OnInit();
}

void CAboutDialog::OnHelp()
{
  ShowHelpWindow(kHelpTopic);
}

bool CAboutDialog::OnButtonClicked(unsigned buttonID, HWND buttonHWND)
{
  LPCTSTR url;
  switch (buttonID)
  {
    case IDB_ABOUT_HOMEPAGE: url = kHomePageURL; break;
    case IDB_ABOUT_FORK_REPO: url = kForkRepoURL; break;
    default:
      return CModalDialog::OnButtonClicked(buttonID, buttonHWND);
  }

  #ifdef UNDER_CE
  SHELLEXECUTEINFO s;
  memset(&s, 0, sizeof(s));
  s.cbSize = sizeof(s);
  s.lpFile = url;
  ::ShellExecuteEx(&s);
  #else
  ::ShellExecute(NULL, NULL, url, NULL, NULL, SW_SHOWNORMAL);
  #endif

  return true;
}
