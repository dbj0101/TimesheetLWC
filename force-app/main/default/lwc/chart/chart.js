import { LightningElement, api, track } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import charts from "@salesforce/resourceUrl/Charts";
import getCurrentHoursData from '@salesforce/apex/TimeSheetReportingController.GetCurrentHoursData';

//https://salesforcespace.blogspot.com/2020/04/how-to-draw-charts-in-lwc.html
//https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.js_third_party_library
//https://www.chartjs.org/docs/latest/general/data-structures.html

//https://github.com/chartjs/Chart.js/releases/
//https://www.chartjs.org/docs/2.7.3/

export default class Chart extends LightningElement {
  countryCovidInfo;
  scriptLoaded = false;
  dataPieArray = [];
  labelPieArray = [];
  colorPieArray = [];
  dataBarArray = [];
  labelBarArray = [];
  colorBarArray = [];

  @api
  set countryCovidInfo(value) {
    getCurrentHoursData().then( result=>{
      let inData={ "dataPie":[40.4, 62.7, 85], 
                  "labelPie":["Project One", "Project Two", "Project Three"], 
                  "colorPie":["#ff0000", "#00ff00", "#0000ff"]
                  ,"dataBar":[22, 18], 
                  "labelBar":["Project Two", "Project Three"], 
                  "colorBar":["#0f0", "#00f"]
                };
      /*let*/ inData = JSON.parse(result);
      console.log('inData:'+JSON.stringify(inData));
      console.log('result:'+JSON.stringify(result));
      this.dataPieArray = inData.dataPie;
      this.labelPieArray = inData.labelPie;
      this.colorPieArray = inData.colorPie;
      this.dataBarArray = inData.dataBar;
      this.labelBarArray = inData.labelBar;
      this.colorBarArray = inData.colorBar;

      if (value) {
        this.loadChartScript(value);
      }
    }).catch(error => {
      console.log('ERROR getCurrentHoursData: '+error.body.message);
      console.error(error);
    });
  }

  get countryCovidInfo() {
    return this.countryCovidInfo;
  }

  loadChartScript(value) {
    // load the script only once
    // Once its loaded, then directly call the methods to draw chart
    if (this.scriptLoaded) {
      this.callDrawPieChart(value);
      this.callDrawBarChart(value);
    } else {
      this.scriptLoaded = true;
      loadScript(this, charts + "/Chart.min.js")
        .then(() => {
          this.callDrawPieChart(value);
          this.callDrawBarChart(value);
        })
        .catch((error) => {
          console.log("Error:", error);
        });
    }
  }

  callDrawPieChart(value) {
    this.drawPieChart(
      value,
      {
        label1: "Total Cases",
        label2: "Total Deaths",
        label3: "TotalRecovered",
        chartLabel: "COVID-19 Data"
      },
      "div.chart1"
    );
  }

  callDrawBarChart(value) {
    this.drawBarChart(
      value,
      {
        label1: "Today's Cases",
        label2: "Today's Deaths",
        chartLabel: "COVID-19 Data"
      },
      "div.chart2"
    );
  }

  drawPieChart(value, labels, className) {
    const config = {
      type: "pie",
      data: {
        datasets: [
          {
            data: this.dataPieArray, 
            backgroundColor: this.colorPieArray,
            label: labels.chartLabel
          }
        ],
        labels: this.labelPieArray 
      },
      options: {
        responsive: true,
        legend: {
          position: "right"
        },
        animation: {
          animateScale: true,
          animateRotate: true
        },
        title: {
          display: true,
          text: "Last 90 Days Hours"
        }
      }
    };
    this.insertChartToDOM(className, config);
  }

  drawBarChart(value, labels, className) {
    const config = {
      type: "bar",
      data: {
        datasets: [
          {
            data: this.dataBarArray, //[1492, 566],//[value.todayCases, value.todayDeaths],
            //backgroundColor: ["rgb(0,188,212)", "rgb(235,69,89)", "rgb(65,244,43)", "rgb(135,69,190)"]
            backgroundColor: this.colorBarArray
          }
        ],
        labels: this.labelBarArray //["Todays Cases", "Todays Deaths"]//[labels.label1, labels.label2]
      },
      options: {
        scales: {
          yAxes: [{
              ticks: {
                  beginAtZero:true
              }
          }]
        },
        responsive: true,
        legend: {
          display: false
        },
        animation: {
          animateScale: true,
          animateRotate: true
        },
        title: {
          display: true,
          text: "Current Week's Hours"
        }
      }
    };
    this.insertChartToDOM(className, config);
  }

  insertChartToDOM(className, config) {
    const canvas = document.createElement("canvas");
    const chartNode = this.template.querySelector(className);
    // clear the old chart from the DOM
    chartNode.innerHTML = "";
    chartNode.appendChild(canvas);
    const ctx = canvas.getContext("2d");
    this.chart = new window.Chart(ctx, config);
  }
}