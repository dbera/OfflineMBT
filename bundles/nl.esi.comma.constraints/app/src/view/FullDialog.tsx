import React , { useEffect } from 'react';
import { createStyles, makeStyles, Theme } from '@material-ui/core/styles';
import Dialog from '@material-ui/core/Dialog';
import AppBar from '@material-ui/core/AppBar';
import Toolbar from '@material-ui/core/Toolbar';
import IconButton from '@material-ui/core/IconButton';
import Typography from '@material-ui/core/Typography';
import CloseIcon from '@material-ui/icons/Close';
import Slide from '@material-ui/core/Slide';
import { TransitionProps } from '@material-ui/core/transitions';
import Box from '@material-ui/core/Box';
import svgPanZoom from '@dash14/svg-pan-zoom';
import dotWorkerScript from "./dotWorker";

interface IFullDialogProps {
    open : boolean;
    content : string;
    option : string;
    handleClickOpen(isOpen: boolean, content: string, option: string): React.MouseEventHandler<HTMLButtonElement>;

}
const useStyles = makeStyles((theme: Theme) =>
  createStyles({
    appBar: {
      position: 'relative',
    },
    title: {
      marginLeft: theme.spacing(2),
      flex: 1,
    },
  }),
);

const Transition = React.forwardRef(function Transition(
    props: TransitionProps & { children?: React.ReactElement },
    ref: React.Ref<unknown>,
  ) {
    return <Slide direction="up" ref={ref} {...props} />;
});

const FullDialog: React.FC<IFullDialogProps> = ({open, content, option, handleClickOpen}) => {
    
    const classes = useStyles();
    const container: React.RefObject<HTMLDivElement> = React.createRef();
    useEffect(() => {  
      //render the constraint graph   
      setTimeout(() => showGraph(), 50);
    });
    let dotWorker: Worker | null = null;
    const cache: {[s: string]: string} = {};
    const getDot = async(output: 'svg'): Promise<string> => {
        const cacheKey = `${output}_1`;
        if (cache[cacheKey]) {
            return cache[cacheKey];
        }
        const dot = atob(content);
        return new Promise((resolve) => {
          dotWorker = new Worker(dotWorkerScript);
          dotWorker.onmessage = (m) => {
            cache[cacheKey] = m.data;
            resolve(m.data);
          };
          dotWorker.postMessage({dot, output});
        });
    };
    function title(){
        if (option === 'feature'){
            return 'Feature File';
        } else {
            return 'Constraint Graph';
        }
    }
    function showContent() {
      if (option === 'feature'){
          return atob(content);
      }
    }
    function showGraph() {
      if (option === 'graph'){
        dotWorker?.terminate();
        renderGraphSVG();
      } 
    }
    const renderGraphSVG = async() => {
      if (!container.current) return;
      const svg = await getDot('svg');
      container.current!.innerHTML = svg;
      const element = container.current!.children[0] as SVGElement;
      if (!element) return;
      element.style.cssText = "width: 100%; height: 100%";
      svgPanZoom(element, {zoomScaleSensitivity: 1, maxZoom: 5});
    };

    return (
        <div>
            <Dialog fullScreen open={open} TransitionComponent={Transition}>
                <AppBar className={classes.appBar}>
                  <Toolbar>
                    <IconButton edge="start" color="inherit" onClick={handleClickOpen(false, "", option)} aria-label="close">
                      <CloseIcon />
                    </IconButton>
                    <Typography variant="h6" className={classes.title}>
                      {title()}
                    </Typography>
                  </Toolbar>
                </AppBar>
                {option === 'feature' && 
                <Box justifyContent="center" m={2} boxShadow={2} p={2} >
                    <Typography style={{ whiteSpace: 'pre-wrap' }}>{showContent()}</Typography>
                </Box>}
                {option === 'graph' && 
                <div style={{width: '100%', height: '100%', position: 'absolute'}} ref={container}/>
                }
            </Dialog>
        </div>
    );
}

export default FullDialog;