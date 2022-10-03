# azure-vm-webapp-activedirectory

---

| Page Type | Languages & Frameworks     | Services |
|-----------|-----------|------------|
| Sample    | PowerShell, C#, ASP.NET    | Virtual Machine<br>Key Vault<br>Active Directory |

---

# Enable Active Directory Authentication on a web application hosted on an Azure VM

This sample codebase demonstrates how to host a web application on an Azure Virtual Machine and authenticate users to it using Azure Active Directory.

## Prerequisite Tools
- [Azure PowerShell](https://learn.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-8.3.0) (for setting up infrastructure via a script)

## Running this sample

### _*Setting Up the Azure Resources*_
#### The core infrastructure needs to be set up before an application can be published and registered with AD services.
1.  To begin, replace the variables with your desired resource names and run the commands in the script found at ```infra/config.ps1```. The script contains Azure PowerShell commands that set up a resource group, key vault, and virtual machine. Additional commands create an self-signed certificate, load it into the Key Vault, and install IIS on the VM.
    - This script closely follows the commands laid out in [this tutorial](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/tutorial-secure-web-server).
    - Please note that the cloud infrastructure can be manually provisioned in the Azure Portal; using ```infra/config.ps1``` is completely optional.
    - You may implement your preferred web server technology - this sample uses IIS throughout.

2. [Create a rule in the Network Security Group](https://learn.microsoft.com/en-us/azure/virtual-network/manage-network-security-group#work-with-security-rules) (which was automatically created with the VM in Step 1) to allow inbound traffic on Port 443 (HTTPS).

3. [Get the fully qualified domain name (FQDN) of the VM you just set up](https://learn.microsoft.com/en-us/azure/virtual-machines/create-fqdn) - you'll use it in the upcoming steps.


### _*Publishing the Application*_
#### Once the resources have been provisioned, the application and authentication solution can be set up.
1. [Create an App Registration](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app#register-an-application).
2. Add the FQDN of the VM as a [Redirect URI](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app#add-a-redirect-uri) in the newly created app registration.
3. On the Quickstart blade, download the [quickstart codebase](https://learn.microsoft.com/en-us/azure/active-directory/develop/reference-v2-libraries) that aligns to your requirements.
    - This project leverages the ASP.NET framework. Codebases for other frameworks (e.g., Java, Node, etc.) are available.
    - The application settings of the quickstart codebase will be preconfigured to reference the credentials of the app registration you created, which the app code will use to authenticate via Azure AD. 
4. Install the codebase's dependencies and publish the codebase on the VM.
    - This may be done by setting up a development environment on the VM, or [through a more advanced DevOps setup](https://devblogs.microsoft.com/premier-developer/using-azure-devops-to-deploy-web-applications-to-virtual-machines/).
5. Serve the application via a web server technology (this project uses IIS).
    - In IIS, a [new website should be created](https://learn.microsoft.com/en-us/iis/get-started/getting-started-with-iis/create-a-web-site) and pointed to the root directory of the application published in Step 4.
    - Create an [SSL binding by adding the self-signed certificate](https://learn.microsoft.com/en-us/iis/manage/configuring-security/how-to-set-up-ssl-on-iis#create-an-ssl-binding-1) generated above to the new website you just created. The hostname should be set as the FQDN of the VM.
    - You may need to grant permissions to the [IIS_IUSR](https://learn.microsoft.com/en-us/troubleshoot/developer/webapps/iis/www-authentication-authorization/understanding-identities#iusr---anonymous-authentication) user to access public areas of the website.
6. [Test the application](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/tutorial-secure-web-server#test-the-secure-web-app) by navigating to ```https://<FQDN of your VM>```. If you used a self-signed certificate, you'll need to accept the security warning. 

### _*Application Architecture*_
![Architecture](/docs/images/diagram.png)

## Limitations/Considerations
- While the general premise will be compatible, the details of _"Publishing the Application"_ may differ slightly if a framework other than ASP.NET is chosen.
- If using RDP to log into the VM on your local computer, you will need to create a Network Security Group rule to allow inbound traffic on Port 3389. This exposes your VM to the public. To connect to your VM using a more secure method, use [Azure Bastion](https://learn.microsoft.com/en-us/azure/bastion/bastion-overview).
- You may set up further [security and stability measures on the VM](https://learn.microsoft.com/en-us/azure/virtual-machines/security-recommendations), including configuring Azure Backup, installing an endpoint protection solution on the VM, and encrypting disks.
- Note that this sample codebase uses a self-signed public certificate - these certificates work well for testing in place of a CA-signed certificate. [Self-signed public certificate are not trusted by default, can be difficult to maintain, and may use outdated hash and cipher suites that may not be strong. Purchasing and using a certificate signed by a well-known certificate authority is the recommended practice outside of testing environments](https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-create-self-signed-certificate).

## Resources
- [Set up IIS on Windows Virtual Machine](https://devblogs.microsoft.com/premier-developer/set-up-iis-on-windows-virtual-machine/)
- [Create a self-signed public certificate to authenticate your application](https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-create-self-signed-certificate)
- [Register an app in the Microsoft identity platform](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
- [Sign in users in web apps using the auth code flow](https://learn.microsoft.com/en-us/azure/active-directory/develop/web-app-quickstart?pivots=devlang-aspnet)
- [Secure a web server on a Windows virtual machine in Azure with TLS/SSL certificates stored in Key Vault
](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/tutorial-secure-web-server)
- [Windows IIS Integration with Azure AD](https://learn.microsoft.com/en-us/answers/questions/11093/windows-iis-integration-with-azure-ad.html)
- [Add sign-in to Microsoft to an ASP.NET web app](https://learn.microsoft.com/en-us/azure/active-directory/develop/tutorial-v2-asp-webapp)