using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace iClipsBrain
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            var dllDirectory = System.IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + "/lib";
            Environment.SetEnvironmentVariable("PATH", Environment.GetEnvironmentVariable("PATH") + ";" + dllDirectory);

            InitializeComponent();
            StringBuilder sb = new StringBuilder();
            sb.AppendLine("(require \"AttentionModule\")");
            sb.AppendLine("(open c:\\users\\face\\desktop\\cicciopasticcio.txt mydata \"w\")");
            sb.AppendLine("(reset)");
            sb.AppendLine("(close)");
            sb.AppendLine("(facts)");
            ClipsEnv.Editor.Text = sb.ToString();
        }

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            ClipsEnv.EmbedEditor = false;
            var w = new Window();
            w.Closing += (o, evt) =>
            {
                w.Content = null;
                ClipsEnv.EmbedEditor = true;
            };
            w.Content = ClipsEnv.Editor;
            
           
           
            w.Show();
        }

        private void cbRun_Checked(object sender, RoutedEventArgs e)
        {
            ClipsEnv.RunTimer.Start();
        }

        private void cbRun_Unchecked(object sender, RoutedEventArgs e)
        {
            ClipsEnv.RunTimer.Stop();
        }
    }
}
