# OfflineMBT
Systems Modeling and Test Generation

### Development environment setup

Follow these instructions to set up a development environment.

To create a development environment (first time only):

- Get the Eclipse Installer:
    - Go to [https://www.eclipse.org/](https://www.eclipse.org/) in a browser.
    - Click on the big **Download** button at the top right.
    - Download Eclipse Installer, 64 bit edition, using the **Download x86_64** button.
- Start the Eclipse Installer that you downloaded.
- Use the hamburger menu at the top right to switch to advanced mode.
- For Windows:
    - When asked to keep the installer in a permanent location, choose to do so.
      Select a directory of your choosing.
    - The Eclipse installer will start automatically in advanced mode, from the new permanent location.
- For Linux:
    - The Eclipse installer will restart in advanced mode.
- Continue with non-first time instructions for setting up a development environment.

To create a development environment:

- Ensure you are using the latest version of the Eclipse Installer:
    - One option is to download it again, as per the 'first time' instructions above.
    - Another option is to update your existing Eclipse Installer.
      In the Eclipse Installer, when in advanced mode, click the 'Install available updates' button.
      This button with the two-arrows icon is located at the bottom-left part of the window, next to the version number.
      Wait for the update to complete and the Eclipse Installer to restart.
      If the button is disabled (grey), you are already using the latest version.
- In the first wizard window:
    - Select **Eclipse Modeling Tools** from the big list at the top.
    - Select **2024-09** for **Product Version**.
    - For **Java 21+ VM** select either the JustJ JRE 21 release or a JRE 21 that is installed on your local machine.
      Use the button to the right of the dropdown to manage the installed virtual machines on your system.
      A JDK can also be downloaded from e.g. [Adoptium](https://adoptium.net/temurin/archive/?variant=openjdk21&jvmVariant=hotspot&version=21).
    - Choose whether you want a P2 bundle pool (recommended).
    - Click the **Next** button.
- In the second wizard window:
    - Use the green '+' icon at the top right to add the Oomph setup.
        - For **Catalog**, choose **Github Projects**.
        - For **Resource URIs**, enter `https://raw.githubusercontent.com/dbera/OfflineMBT/main/OfflineMBT.setup` and make sure there are no spaces before or after the URL.
        - Click the **OK** button.
    - Check the checkbox for **OfflineMBT**, from the big list.
      It is under **Github Projects** / **<User>**.
    - At the bottom right, select the **Main** stream.
    - Click the **Next** button.
- In the third wizard window:
    - Enable the **Show all variables** option to show all options.
    - Choose a **Root install folder** and _Installation folder name_.
      The new development environment will be put at `<root_installation_folder>/<installation_folder_name>`.
    - Fill in the **OfflineMBT Github repository**:
        - Committers with write access to the official Github repository can use one of the default URLs `Git (read-write)` or `HTTPS (read-write)`.
        - Contributors can use the `HTTPS (read-only, anonymous)` URL, as they don't have write access.
          They will not be able to push to the remote repository, they can instead make a fork of the official Git repository.
          Then they can fill in the URL of their clone instead, i.e. `https://${github.user.id|username}@github.com/<username>/<cloned_repo_name>.git`, with `<username>` replaced by their Github account username, and `<cloned_repo_name>` replaced by the name of the cloned repistory, which defaults to `OfflineMBT`.
    - Fill in your **Github author name** and **Github author email**.
      These will be used for Git commits.
    - Check that the **Target platform** is set to **2024-09**.
    - Click the **Next** button.
- In the fourth wizard window:
    - Select the **Finish** button.
- Wait for the setup to complete and the development environment to be launched.
    - If asked, accept any licenses and certificates.
- Press the **Finish** button in the Eclipse Installer to close the Eclipse Installer.
- In the new development environment, observe Oomph executing the startup tasks (such as Git clone, importing projects, etc).
  If this is not automatically shown, click the rotating arrows icon in the status bar (bottom right) of the new development environment.
- Wait for the startup tasks to finish successfully.

> [!NOTE]
> If you don't open the Oomph dialog, the status bar icon may disappear when the tasks are successfully completed.

If you have any issues during setting up the development environment, consider the following:

You can set the following environment variables to force the use of IPv4, in case of any issues accessing/downloading remote files:

```
_JAVA_OPTIONS=-Djava.net.preferIPv4Stack=true
_JPI_VM_OPTIONS=-Djava.net.preferIPv4Stack=true
```

After setting them, make sure to fully close the Eclipse Installer and then start it again, for the changes to be picked up.

In your new development environment, consider changing the following settings:

- For the **Package Explorer** view:

    - Enable the **Link with Editor** setting, using the ![](https://git.eclipse.org/c/jdt/eclipse.jdt.ui.git/plain/org.eclipse.jdt.ui/icons/full/elcl16/synced.png) icon.

    - Enable showing resources (files/folders) with names starting with a period.
      Open the **View Menu** (![](https://git.eclipse.org/c/platform/eclipse.platform.ui.git/plain/bundles/org.eclipse.ui/icons/full/elcl16/view_menu.png) > ![](https://git.eclipse.org/c/jdt/eclipse.jdt.ui.git/plain/org.eclipse.jdt.ui/icons/full/elcl16/filter_ps.png) Filters...).
      Uncheck the `.* resources` option and click the **OK** button.

### Building with Maven

> [!CAUTION]
> OfflineMBT should be built using [Maven 3.9](https://maven.apache.org/download.cgi) and a _Java 21 VM_.
> The JDK can be downloaded from e.g. [Adoptium](https://adoptium.net/temurin/archive/?variant=openjdk21&jvmVariant=hotspot&version=21).
>
> To test which Java version is used by Maven, type `mvn -version` in a command shell.

To build OfflineMBT with Maven execute the following command in the root:

`mvn clean package -P site`

On a successful build, the built Eclipse P2 repository can be found in the **target** folder of the [releng/nl.esi.comma.standard.site](releng/nl.esi.comma.standard.site/) project.
