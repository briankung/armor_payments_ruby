require 'spec_helper'

module ArmorPayments
  describe Resource do
    let(:authenticator) { Authenticator.new('my-api-key', 'my-secret-code') }
    let(:host) { 'https://sandbox.armorpayments.com' }
    let(:uri_root) { '/wibble/123' }
    let(:resource) { Resource.new(host, authenticator, uri_root) }
    let(:successful_response) { Excon::Response.new(status: 200, body: '{"whee":42}', headers: { 'Content-Type' => 'application/json' }) }

    describe "#uri" do
      it "returns '/%{uri_root}/resource_name' if given no id" do
        resource.uri.should == '/wibble/123/resource'
      end

      it "returns '/%{uri_root}/resource_name/:id' if given an id" do
        resource.uri(456).should == '/wibble/123/resource/456'
      end
    end

    describe "#request" do
      context "on a response with a JSON body" do
        it "returns the parsed JSON body" do
          resource.connection.stub(:get).and_return(successful_response)
          response = resource.request('get', {})
          response.body.should == { 'whee' => 42 }
        end
      end

      context "on a response without JSON" do
        it "returns the full response object" do
          failed_response = Excon::Response.new(status: 502, body: 'Gateway Timeout')
          resource.connection.stub(:get).and_return(failed_response)
          response = resource.request('get', {})
          response.body.should == 'Gateway Timeout'
        end
      end
    end

    context "smoketest" do
      describe "#all" do
        it "queries the host for all of the resources, with approprate headers" do
          Timecop.freeze(2014, 2, 22, 12, 0, 0) do
            resource.connection.should_receive(:get).with({
              path: '/wibble/123/resource',
              headers: {
                "X_ARMORPAYMENTS_APIKEY"            => "my-api-key",
                "X_ARMORPAYMENTS_REQUESTTIMESTAMP"  => "2014-02-22T17:00:00Z",
                "X_ARMORPAYMENTS_SIGNATURE"         => "ec41629dc204b449c71bf89d1be4630f5353e37869197f5a926539f6fc676ebcccdb5426fb3f01a01fa7dc9551d38d152e41294a5147b15e460d09ff60cf1562"
              }
            }).and_return(successful_response)

            resource.all
          end
        end
      end

      describe "#get" do
        it "queries the host for a specific resource, with approprate headers" do
          Timecop.freeze(2014, 2, 22, 12, 0, 0) do
            resource.connection.should_receive(:get).with({
              path: '/wibble/123/resource/456',
              headers: {
                "X_ARMORPAYMENTS_APIKEY"            => "my-api-key",
                "X_ARMORPAYMENTS_REQUESTTIMESTAMP"  => "2014-02-22T17:00:00Z",
                "X_ARMORPAYMENTS_SIGNATURE"         => "48886620cfebb95ffd9ee351f4f68d4f103a8f4bdc0e3301f7ee709ec2cf3c19588ae1b67aa8ee38305de802651fb10093cf1af40f467ac936185d551a58a844"
              }
            }).and_return(successful_response)

            resource.get(456)
          end
        end
      end

    end

  end
end