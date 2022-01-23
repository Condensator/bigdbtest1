SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AgencyLegalPlacements](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PlacementNumber] [bigint] NOT NULL,
	[PlacementType] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[PlacementPurpose] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[DateOfPlacement] [date] NOT NULL,
	[FeeStructure] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[Fee_Amount] [decimal](16, 2) NULL,
	[Fee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ContingencyPercentage] [decimal](5, 2) NULL,
	[AgencyFileNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[Outcome] [nvarchar](26) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[VendorId] [bigint] NULL,
	[CustomerId] [bigint] NOT NULL,
	[LegalReliefId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[BusinessUnitId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AgencyLegalPlacements]  WITH CHECK ADD  CONSTRAINT [EAgencyLegalPlacement_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[AgencyLegalPlacements] CHECK CONSTRAINT [EAgencyLegalPlacement_BusinessUnit]
GO
ALTER TABLE [dbo].[AgencyLegalPlacements]  WITH CHECK ADD  CONSTRAINT [EAgencyLegalPlacement_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[AgencyLegalPlacements] CHECK CONSTRAINT [EAgencyLegalPlacement_Customer]
GO
ALTER TABLE [dbo].[AgencyLegalPlacements]  WITH CHECK ADD  CONSTRAINT [EAgencyLegalPlacement_LegalRelief] FOREIGN KEY([LegalReliefId])
REFERENCES [dbo].[LegalReliefs] ([Id])
GO
ALTER TABLE [dbo].[AgencyLegalPlacements] CHECK CONSTRAINT [EAgencyLegalPlacement_LegalRelief]
GO
ALTER TABLE [dbo].[AgencyLegalPlacements]  WITH CHECK ADD  CONSTRAINT [EAgencyLegalPlacement_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[AgencyLegalPlacements] CHECK CONSTRAINT [EAgencyLegalPlacement_Vendor]
GO
