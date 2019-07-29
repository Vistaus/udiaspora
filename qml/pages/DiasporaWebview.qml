
import QtQml 2.2
import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtGraphicalEffects 1.0
import QtWebEngine 1.7

import "../components"
import "../components/dialogs"

Page {
	id: webviewPage
	width: parent.width
	height: parent.height

	header:Item {
		height: 0
		visible: false
	}
	
	Component {
		id: pickerComponent
		PickerDialog {}
	}
	


	Item {
		id:webContainer
		anchors {
			top:parent.top
			left:parent.left
			right:parent.right
			bottom:bottomControls.top
		}
		MainWebView {
			id:webView
			url: helperFunctions.getInstanceURL()
			filePicker: pickerComponent
			confirmDialog: ConfirmDialog {}
			alertDialog: AlertDialog {}
			promptDialog:PromptDialog {}
			onLoadProgressChanged: {
				loadingPage.progressBar.value = loadProgress
			}
			settings.showScrollBars:false

			// Open external URL's in the browser and not in the app
			onNavigationRequested: {
// 				for(var i in request) {
// 					console.log(i,request[i]);
// 				}
				console.log ( request.url, ("" + request.url).indexOf ( appSettings.instance ) !== -1 )
				if ( ("" + request.url).indexOf ( appSettings.instance ) !== -1 || !appSettings.openLinksExternally ) {
					request.action = 0
				} else if(request.navigationType == 1) {
					request.action = 1
					Qt.openUrlExternally( request.url )
				}
			}

			onNewViewRequested: {
				request.action = 1
				if ( !appSettings.openLinksExternally ) {
					webView.url = request.requestedUrl
				} else {
					Qt.openUrlExternally( request.requestedUrl )
				}
			}
		}
	}

	LoadingPage {
		id:loadingPage
		anchors.fill: parent

		hasLoadError:  ( typeof(webviewPage.currentView()) !== 'undefined' && !webviewPage.currentView().loading && webviewPage.currentView().lastStatus == WebEngineView.LoadFailedStatus )

		visible: opacity != 0
		opacity: !webviewPage.currentView().isLoaded ? 1 : 0
		Behavior on opacity { NumberAnimation { duration:UbuntuAnimation.BriskDuration} }

		onReloadButtonPressed: webviewPage.currentView().reload();
	}


	ProgressBar {
			id: _bottomProgressBar
			z:2
			anchors.bottom:instancBottomEdge.status !== BottomEdge.Committed ? bottomControls.top : instancBottomEdge.top
			anchors.bottomMargin: 1
			width: instancBottomEdge.width

			visible: webviewPage.currentView().visible && webviewPage.currentView().loading

			value:  webviewPage.currentView().loadProgress
			indeterminate: value == 0
			minimumValue: 0
			maximumValue: 100
			StyleHints {
				foregroundColor: loadingPage.hasLoadError ?
									theme.palette.normal.negative :
									theme.palette.normal.progress
			}
			layer.enabled: true
			layer.effect:DropShadow {
				radius: 7
				transparentBorder:true
				color:theme.palette.highlighted.selected
			}
		}

	BottomEdgeControlsHeader {
		id:bottomControls
		z:2
		anchors.bottom: parent.bottom
		anchors.bottomMargin : visible ? 0 : -height
		visible: webviewPage.currentView().visible && ( !appSettings.hideBottomControls || !webviewPage.isOnDiaspora() );
		trailingSlots: !webviewPage.isOnDiaspora() ? 4 : 3
		
		leadingActionBar {
			numberOfSlots:6
			visible:webviewPage.isOnDiaspora()
			actions: [
				Action {
					text:i18n.tr("Add Post")
					iconName:"edit"
					onTriggered:instancBottomEdge.commit();
				},			
				Action {
					text:i18n.tr("Messages")
					iconName:"messages"
					onTriggered:webviewPage.currentView().url = helperFunctions.getInstanceURL() +"/conversations";
				},			
				Action {
					text:i18n.tr("Notifications")
					iconName:"notification"
					onTriggered:webviewPage.currentView().url = helperFunctions.getInstanceURL() +"/notifications";
				},
				Action {
					enabled:false
				},
				Action {
					text:i18n.tr("Stream")
					iconSource:"../../assets/diaspora-asterisk.png"
					onTriggered:webviewPage.currentView().goHome();
				}
			]
		}
	}

	BottomEdge {
		id: instancBottomEdge
		visible: webviewPage.currentView().visible  && webviewPage.isOnDiaspora()
		height:units.gu(45)
		hint.iconName: "go-up"
		hint.visible:visible
		preloadContent: false
		contentComponent: Component { 
			AddPost {
				anchors.fill:instancBottomEdge
				height:instancBottomEdge.height
				width:instancBottomEdge.width
				filePickerComponent:pickerComponent
			}
		}

		onCommitStarted: contentItem.resetURL();
	}
	
	//========================== Functions =======================
	function currentView() {
		return  appSettings.incognitoMode ? webViewIncogito : webView;
	}
	
	function  isOnDiaspora() {
		return (currentView().url.toString().indexOf(appSettings.instance) !== -1)
	}
	
	function isLoggedin() {
		var loginPage = helperFunctions.getInstanceURL() + "/users/sign_in"
		return currentView().url != loginPage;
	}

}
