using PurificationPioneer.Const;
using PurificationPioneer.Network.Proxy;
using PurificationPioneer.Scriptable;
using ReadyGamerOne.Common;
using ReadyGamerOne.View;

namespace PurificationPioneer.View
{
	public partial class WelcomePanel
	{
		private WelcomePanelScript script;
		partial void OnLoad()
		{
			//do any thing you want
			script = m_TransFrom.GetComponent<WelcomePanelScript>();
			
			
			script.loginBtn.onClick.AddListener(() =>
			{
				AuthProxy.Instance.Login(script.account.text,script.password.text);
			});


#if UNITY_EDITOR
			if (GameSettings.Instance.DebugMode)
			{
				script.account.text = GameSettings.Instance.DebugAccount;
				script.password.text = GameSettings.Instance.DebugPassword;
			}
#endif
		}

		protected override void OnAddListener()
		{
			base.OnAddListener();
			CEventCenter.AddListener(Message.OnUserLogin, OnUserLogin);
		}


		protected override void OnRemoveListener()
		{
			base.OnRemoveListener();
			CEventCenter.RemoveListener(Message.OnUserLogin,OnUserLogin);
		}
		
		
		private void OnUserLogin()
		{
			PanelMgr.PushPanel(PanelName.HomePanel);
		}
	}
}
