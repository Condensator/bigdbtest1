SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UDFValueAssignmentForParties](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[UDF1Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF2Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF3Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF4Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF5Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UDFLabelForPartyDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[EntityType] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[UDFValueAssignmentForParties]  WITH CHECK ADD  CONSTRAINT [EUDFValueAssignmentForParty_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[UDFValueAssignmentForParties] CHECK CONSTRAINT [EUDFValueAssignmentForParty_Portfolio]
GO
ALTER TABLE [dbo].[UDFValueAssignmentForParties]  WITH CHECK ADD  CONSTRAINT [EUDFValueAssignmentForParty_UDFLabelForPartyDetail] FOREIGN KEY([UDFLabelForPartyDetailId])
REFERENCES [dbo].[UDFLabelForPartyDetails] ([Id])
GO
ALTER TABLE [dbo].[UDFValueAssignmentForParties] CHECK CONSTRAINT [EUDFValueAssignmentForParty_UDFLabelForPartyDetail]
GO
