`timescale 1ns / 1ps

module custom_axi4lite_tb;

    // =========================================================
    // AXI parameters
    // =========================================================

    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 4;

    // =========================================================
    // Clock and reset
    // =========================================================

    reg clk;
    reg resetn;

    // =========================================================
    // AXI WRITE CHANNEL
    // =========================================================

    reg [ADDR_WIDTH-1:0] awaddr;
    reg [2:0] awprot;
    reg awvalid;
    wire awready;

    reg [DATA_WIDTH-1:0] wdata;
    reg [(DATA_WIDTH/8)-1:0] wstrb;
    reg wvalid;
    wire wready;

    // =========================================================
    // AXI WRITE RESPONSE
    // =========================================================

    wire [1:0] bresp;
    wire bvalid;
    reg bready;

    // =========================================================
    // AXI READ CHANNEL
    // =========================================================

    reg [ADDR_WIDTH-1:0] araddr;
    reg [2:0] arprot;
    reg arvalid;
    wire arready;

    wire [DATA_WIDTH-1:0] rdata;
    wire [1:0] rresp;
    wire rvalid;
    reg rready;

    // =========================================================
    // DUT
    // =========================================================

    custom_axi4lite_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(ADDR_WIDTH)
    ) DUT (

        .S_AXI_ACLK    (clk),
        .S_AXI_ARESETN (resetn),

        .S_AXI_AWADDR  (awaddr),
        .S_AXI_AWPROT  (awprot),
        .S_AXI_AWVALID (awvalid),
        .S_AXI_AWREADY (awready),

        .S_AXI_WDATA   (wdata),
        .S_AXI_WSTRB   (wstrb),
        .S_AXI_WVALID  (wvalid),
        .S_AXI_WREADY  (wready),

        .S_AXI_BRESP   (bresp),
        .S_AXI_BVALID  (bvalid),
        .S_AXI_BREADY  (bready),

        .S_AXI_ARADDR  (araddr),
        .S_AXI_ARPROT  (arprot),
        .S_AXI_ARVALID (arvalid),
        .S_AXI_ARREADY (arready),

        .S_AXI_RDATA   (rdata),
        .S_AXI_RRESP   (rresp),
        .S_AXI_RVALID  (rvalid),
        .S_AXI_RREADY  (rready)
    );

    // =========================================================
    // CLOCK
    // 100 MHz
    // =========================================================

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // =========================================================
    // INITIALIZATION
    // =========================================================

    initial begin

        resetn  = 0;

        awaddr  = 0;
        awprot  = 0;
        awvalid = 0;

        wdata   = 0;
        wstrb   = 4'b1111;
        wvalid  = 0;

        bready  = 0;

        araddr  = 0;
        arprot  = 0;
        arvalid = 0;

        rready  = 0;

        // Reset
        #100;
        resetn = 1;

        #20;

        // =====================================================
        // TEST 1
        // Load counter with 100
        // Address 0x04
        // =====================================================

        $display("----------------------------------------");
        $display("TEST 1: Loading counter with 100");
        $display("----------------------------------------");

        axi_write(4'h4, 32'd100);

        // =====================================================
        // TEST 2
        // Enable counter
        // Address 0x00
        // =====================================================

        $display("----------------------------------------");
        $display("TEST 2: Enabling counter");
        $display("----------------------------------------");

        axi_write(4'h0, 32'd1);

        // =====================================================
        // Let counter run
        // =====================================================

        #100;

        // =====================================================
        // TEST 3
        // Read counter
        // Address 0x08
        // =====================================================

        $display("----------------------------------------");
        $display("TEST 3: Reading counter");
        $display("----------------------------------------");

        axi_read(4'h8);
        
         if (rdata >= 32'd100)
    $display("PASS: Counter incremented correctly");
        else
    $display("FAIL: Counter did not increment");
    
        // =====================================================
        // TEST 4
        // Read status
        // Address 0x0C
        // =====================================================

        $display("----------------------------------------");
        $display("TEST 4: Reading status");
        $display("----------------------------------------");

        axi_read(4'hC);
         
         if (rdata == 32'd1)
    $display("PASS: Status is ENABLED");
         else
    $display("FAIL: Status is incorrect");
     
        // =====================================================
        // TEST 5
        // Disable counter
        // =====================================================

        $display("----------------------------------------");
        $display("TEST 5: Disabling counter");
        $display("----------------------------------------");

        axi_write(4'h0, 32'd0);

        #50;

        // =====================================================
        // Finish
        // =====================================================

        $display("----------------------------------------");
        $display("TEST COMPLETE");
        $display("----------------------------------------");

        $finish;

    end

    // =========================================================
    // AXI WRITE TASK
    // =========================================================

    task axi_write;

        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;

        begin

            @(posedge clk);

            awaddr  <= addr;
            awvalid <= 1'b1;

            wdata   <= data;
            wvalid  <= 1'b1;

            wstrb   <= 4'b1111;

            bready  <= 1'b1;

            // Wait for address and data handshake
            wait(awready && wready);

            @(posedge clk);

            awvalid <= 1'b0;
            wvalid  <= 1'b0;

            // Wait for write response
            wait(bvalid);

            @(posedge clk);

            bready <= 1'b0;

            $display("WRITE: Address = 0x%h, Data = %0d",
                     addr, data);

        end

    endtask

    // =========================================================
    // AXI READ TASK
    // =========================================================

    task axi_read;

        input [ADDR_WIDTH-1:0] addr;

        begin

            @(posedge clk);

            araddr  <= addr;
            arvalid <= 1'b1;

            rready  <= 1'b1;

            // Wait for address handshake
            wait(arready);

            @(posedge clk);

            arvalid <= 1'b0;

            // Wait for read data
            wait(rvalid);

            @(posedge clk);

            $display("READ: Address = 0x%h, Data = %0d",
                     addr, rdata);

            rready <= 1'b0;

        end

    endtask

endmodule